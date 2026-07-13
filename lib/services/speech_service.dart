import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();

  bool _isInitialized = false;

  bool get isListening => _speech.isListening;

  Future<bool> initialize({
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    if (_isInitialized) {
      return true;
    }

    _isInitialized = await _speech.initialize(
      onStatus: onStatus,
      onError: (error) => onError?.call(error.errorMsg),
    );
    return _isInitialized;
  }

  Future<void> startListening({
    required void Function(String transcript) onTranscript,
    void Function(String status)? onStatus,
    void Function(String error)? onError,
  }) async {
    final available = await initialize(
      onStatus: onStatus,
      onError: onError,
    );
    if (!available) {
      throw Exception('Speech recognition is not available on this device.');
    }

    await _speech.listen(
      onResult: (result) {
        debugPrint('Recognized: ${result.recognizedWords}');
        onTranscript(result.recognizedWords);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      localeId: 'en_US',
      listenOptions: SpeechListenOptions(
        partialResults: true,
        listenMode: ListenMode.dictation,
        cancelOnError: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }

  Future<void> cancelListening() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
  }
}
