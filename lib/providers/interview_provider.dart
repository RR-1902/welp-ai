import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';

import '../models/interview_config.dart';
import '../models/interview_turn.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/camera_service.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../utils/helpers.dart';

class InterviewProvider extends ChangeNotifier {
  ApiService? _apiService;
  SpeechService? _speechService;
  TtsService? _ttsService;
  CameraService? _cameraService;

  InterviewConfig? _config;
  final List<MessageModel> _messages = [];
  final List<InterviewTurn> _turns = [];

  bool _isBusy = false;
  bool _isListening = false;
  bool _isSpeaking = false;
  bool _isInterviewStarted = false;
  bool _isInterviewCompleted = false;
  String _currentQuestion = '';
  String _draftResponse = '';
  String _finalSummary = '';
  String? _errorMessage;
  int _questionCount = 0;
  bool _ttsEnabled = false;

  void attachServices({
    required ApiService apiService,
    required SpeechService speechService,
    required TtsService ttsService,
    required CameraService cameraService,
  }) {
    _apiService = apiService;
    _speechService = speechService;
    _ttsService = ttsService;
    _cameraService = cameraService;
  }

  InterviewConfig? get config => _config;
  List<MessageModel> get messages => List.unmodifiable(_messages);
  List<MessageModel> get visibleMessages => List.unmodifiable(
        _messages.where(
          (message) => !message.isUser || !message.content.startsWith('Start the interview now.'),
        ),
      );
  List<InterviewTurn> get turns => List.unmodifiable(_turns);
  bool get isBusy => _isBusy;
  bool get isTyping => _isBusy;
  bool get isListening => _isListening;
  bool get isSpeaking => _isSpeaking;
  bool get isInterviewStarted => _isInterviewStarted;
  bool get isInterviewCompleted => _isInterviewCompleted;
  String get currentQuestion => _currentQuestion;
  String get draftResponse => _draftResponse;
  String get finalSummary => _finalSummary;
  String? get errorMessage => _errorMessage;
  double get averageScore => Helpers.averageScore(_turns);
  int get questionCount => _questionCount;
  int get maxQuestions => _config?.questionCount ?? 0;
  int get completedAnswers => _turns.length;
  int get currentQuestionNumber => _questionCount;
  CameraController? get cameraController => _cameraService?.controller;
  bool get isCameraReady => _cameraService?.isInitialized ?? false;

  void setTtsEnabled(bool value) {
    _ttsEnabled = value;
  }

  Future<bool> initializeSpeech() async {
    try {
      final initialized = await _speechService?.initialize(
            onStatus: (status) => debugPrint('Speech status: $status'),
            onError: (error) => debugPrint('Speech error: $error'),
          ) ??
          false;
      if (!initialized) {
        _errorMessage = 'Speech recognition could not be initialized.';
        notifyListeners();
      }
      return initialized;
    } catch (error) {
      _errorMessage = error.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> speakCurrentQuestionIfReady() async {
    if (_currentQuestion.trim().isEmpty || !_ttsEnabled) {
      return;
    }
    await _speakAssistantText(_currentQuestion);
  }

  Future<void> startInterview(InterviewConfig config) async {
    final sanitizedConfig = config.copyWith(
      questionCount: config.questionCount.clamp(5, 10),
    );

    _setBusy(true);
    _errorMessage = null;
    _config = sanitizedConfig;
    _messages.clear();
    _turns.clear();
    _finalSummary = '';
    _draftResponse = '';
    _currentQuestion = '';
    _isInterviewStarted = false;
    _isInterviewCompleted = false;
    _questionCount = 0;
    notifyListeners();

    try {
      if (sanitizedConfig.includeCamera) {
        await _cameraService?.initialize();
      }
      await _ttsService?.initialize();

      const firstQuestion = 'Tell me about yourself.';
      _currentQuestion = firstQuestion;
      _questionCount = 1;
      _isInterviewStarted = true;
      _messages.add(
        MessageModel(
          role: 'assistant',
          content: firstQuestion,
          timestamp: DateTime.now(),
          questionNumber: 1,
          isQuestion: true,
        ),
      );

    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> updateDraft(String value) async {
    if (_isSpeaking) {
      await stopSpeaking();
    }
    _draftResponse = value;
    notifyListeners();
  }

  Future<void> toggleListening() async {
    if (_isListening) {
      await _speechService?.stopListening();
      _isListening = false;
      notifyListeners();
      return;
    }

    try {
      if (_isSpeaking) {
        await stopSpeaking();
      }
      await _speechService?.startListening(
        onTranscript: (transcript) {
          _draftResponse = transcript;
          notifyListeners();
        },
        onStatus: (status) {
          final normalizedStatus = status.toLowerCase();
          if (normalizedStatus == 'done' || normalizedStatus == 'notlistening') {
            _isListening = false;
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = error;
          _isListening = false;
          notifyListeners();
        },
      );
      _isListening = true;
      _errorMessage = null;
      notifyListeners();
    } catch (error) {
      _errorMessage = error.toString();
      _isListening = false;
      notifyListeners();
    }
  }

  Future<void> stopSpeaking() async {
    await _ttsService?.stop();
    _isSpeaking = false;
    notifyListeners();
  }

  Future<void> stopListening() async {
    await _speechService?.stopListening();
    _isListening = false;
    notifyListeners();
  }

  Future<void> submitResponse() async {
    if (_draftResponse.trim().isEmpty || _config == null || _currentQuestion.isEmpty) {
      return;
    }

    _setBusy(true);
    _errorMessage = null;

    final answer = _draftResponse.trim();
    final askedQuestion = _currentQuestion;
    _draftResponse = '';

    if (_isListening) {
      await _speechService?.stopListening();
      _isListening = false;
    }
    if (_isSpeaking) {
      await stopSpeaking();
    }
    notifyListeners();

    try {
      final imageBase64 =
          _config!.includeCamera ? await _cameraService?.captureFrameBase64() : null;

      _messages.add(
        MessageModel(
          role: 'user',
          content: answer,
          timestamp: DateTime.now(),
        ),
      );

      final reply = await _apiService!.sendMessage(
        _messages,
        system: Helpers.buildInterviewSystemPrompt(
          role: _config!.role,
          mode: _config!.mode,
          difficulty: _config!.difficulty,
          persona: _config!.persona,
          questionCount: _config!.questionCount,
          topic: _config!.customTopic,
          hasResume: _config!.resumePath != null,
        ),
        imageBase64: imageBase64,
      );
      await Future<void>.delayed(const Duration(seconds: 1));

      final payload = Helpers.parseAiPayload(reply);
      final feedback = _normalizeFeedback(
        (payload['feedback'] as String? ?? '').trim(),
      );
      final nextQuestion = _normalizeQuestion(
        (payload['question'] as String? ?? '').trim(),
      );
      final score = ((payload['score'] as num?)?.round() ?? 72).clamp(0, 100);
      final shouldEnd = payload['shouldEnd'] as bool? ?? false;
      final summary = (payload['summary'] as String? ?? '').trim();

      _turns.add(
        InterviewTurn(
          question: askedQuestion,
          answer: answer,
          feedback: feedback,
          score: score,
        ),
      );

      _messages.add(
        MessageModel(
          role: 'assistant',
          content: feedback,
          timestamp: DateTime.now(),
          score: score,
          feedback: feedback,
          questionNumber: _turns.length,
        ),
      );

      final reachedLimit = _turns.length >= _config!.questionCount;
      if (shouldEnd || reachedLimit || nextQuestion.isEmpty) {
        _currentQuestion = '';
        _finalSummary = summary.isEmpty
            ? 'Interview completed. Review your strongest answers and tighten your weaker ones.'
            : summary;
        _isInterviewCompleted = true;
        _messages.add(
          MessageModel(
            role: 'assistant',
            content: _finalSummary,
            timestamp: DateTime.now(),
          ),
        );
        await _speakAssistantText('$feedback ${_finalSummary.trim()}');
      } else {
        _currentQuestion = nextQuestion;
        _questionCount = _turns.length + 1;
        _messages.add(
          MessageModel(
            role: 'assistant',
            content: nextQuestion,
            timestamp: DateTime.now(),
            questionNumber: _questionCount,
            isQuestion: true,
          ),
        );
        await _speakAssistantText('$feedback Next question. $nextQuestion');
      }
    } catch (error) {
      final payload = Helpers.buildMockInterviewPayload(
        questionNumber: _turns.length + 1,
        maxQuestions: _config!.questionCount,
        role: _config!.topicLabel,
        latestAnswer: answer,
        hasResume: _config!.resumePath != null,
      );
      final feedback = _normalizeFeedback(payload['feedback'] as String? ?? '');
      final nextQuestion = _normalizeQuestion(payload['question'] as String? ?? '');
      final score = ((payload['score'] as num?)?.round() ?? 78).clamp(0, 100);
      final shouldEnd = payload['shouldEnd'] as bool? ?? false;
      final summary = payload['summary'] as String? ?? '';

      _turns.add(
        InterviewTurn(
          question: askedQuestion,
          answer: answer,
          feedback: feedback,
          score: score,
        ),
      );
      _messages.add(
        MessageModel(
          role: 'assistant',
          content: feedback,
          timestamp: DateTime.now(),
          score: score,
          feedback: feedback,
          questionNumber: _turns.length,
        ),
      );

      if (shouldEnd || nextQuestion.isEmpty) {
        _currentQuestion = '';
        _finalSummary = summary;
        _isInterviewCompleted = true;
        _messages.add(
          MessageModel(
            role: 'assistant',
            content: _finalSummary,
            timestamp: DateTime.now(),
          ),
        );
        await _speakAssistantText('$feedback $_finalSummary');
      } else {
        _currentQuestion = nextQuestion;
        _questionCount = _turns.length + 1;
        _messages.add(
          MessageModel(
            role: 'assistant',
            content: nextQuestion,
            timestamp: DateTime.now(),
            questionNumber: _questionCount,
            isQuestion: true,
          ),
        );
        await _speakAssistantText('$feedback Next question. $nextQuestion');
      }
      _errorMessage =
          'Live AI connection failed, so the app switched to demo fallback mode.';
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> triggerMotivationalFeedback(String issue) async {
    if (_config == null || _isBusy) {
      return;
    }

    _setBusy(true);
    _errorMessage = null;
    notifyListeners();

    final promptMessage = 'User looks distracted. Give motivational feedback.'
        ' Issue detected: $issue.';

    try {
      final coachingPrompt = '''
You are a supportive interview coach.
The app detected this issue: $issue.
Respond with a short motivational coaching message in 1 or 2 sentences.
Do not ask a new interview question.
Do not use markdown.
''';

      final coachingMessages = [
        ..._messages,
        MessageModel(
          role: 'user',
          content: promptMessage,
          timestamp: DateTime.now(),
        ),
      ];

      final reply = await _apiService!.sendMessage(
        coachingMessages,
        system: coachingPrompt,
      );

      _messages.add(
        MessageModel(
          role: 'assistant',
          content: reply.trim().isEmpty
              ? 'Maintain eye contact, settle your posture, and stay confident. You are doing well.'
              : reply.trim(),
          timestamp: DateTime.now(),
        ),
      );
      await _speakAssistantText(_messages.last.content);
    } catch (_) {
      _messages.add(
        MessageModel(
          role: 'assistant',
          content:
              'Maintain eye contact, settle your posture, and stay confident. You are doing well.',
          timestamp: DateTime.now(),
        ),
      );
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> uploadResume(String filePath) async {
    _setBusy(true);
    _errorMessage = null;
    notifyListeners();
    try {
      await _apiService?.uploadResume(filePath);
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> resetSession() async {
    await _speechService?.cancelListening();
    await _ttsService?.stop();
    await _cameraService?.dispose();
    _messages.clear();
    _turns.clear();
    _config = null;
    _isBusy = false;
    _isListening = false;
    _isSpeaking = false;
    _isInterviewStarted = false;
    _isInterviewCompleted = false;
    _currentQuestion = '';
    _draftResponse = '';
    _finalSummary = '';
    _errorMessage = null;
    _questionCount = 0;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
  }

  String _normalizeQuestion(String value) {
    return value.trim();
  }

  String _normalizeFeedback(String value) {
    if (value.isNotEmpty) {
      return value;
    }
    return 'Solid effort. Add more structure, specificity, and measurable impact to strengthen the answer.';
  }

  Future<void> _speakAssistantText(String text) async {
    if (text.trim().isEmpty || !_ttsEnabled) {
      return;
    }
    _isSpeaking = true;
    notifyListeners();
    await _ttsService?.speak(text);
    _isSpeaking = false;
    notifyListeners();
  }
}
