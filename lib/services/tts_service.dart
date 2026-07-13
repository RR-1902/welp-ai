import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  bool get isSpeaking => _isSpeaking;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }

    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.46);
    await _tts.awaitSpeakCompletion(true);
    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setCancelHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((_) => _isSpeaking = false);
    _isInitialized = true;
  }

  Future<void> speak(String text) async {
    await initialize();
    if (text.trim().isEmpty) {
      return;
    }
    await _tts.stop();
    _isSpeaking = true;
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await initialize();
    _isSpeaking = false;
    await _tts.stop();
  }
}
