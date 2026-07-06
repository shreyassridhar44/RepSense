import 'package:speech_to_text/speech_to_text.dart';
import '../../../core/utils/app_logger.dart';

/// Service for voice-to-text input
class VoiceInputService {
  final SpeechToText _speech = SpeechToText();
  bool _isInitialized = false;

  /// Initialize speech recognition
  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) => AppLogger.error('Speech recognition error', error),
        onStatus: (status) => AppLogger.debug('Speech status: $status'),
      );
      return _isInitialized;
    } catch (e) {
      AppLogger.error('Failed to initialize speech recognition', e);
      return false;
    }
  }

  /// Start listening
  Future<void> startListening({
    required void Function(String text) onPartialResult,
    required void Function(String finalText) onFinalResult,
    required void Function(String error) onError,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError('Speech recognition not available');
        return;
      }
    }

    try {
      await _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            onFinalResult(result.recognizedWords);
          } else {
            onPartialResult(result.recognizedWords);
          }
        },
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      AppLogger.error('Failed to start listening', e);
      onError('Failed to start voice input');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (e) {
      AppLogger.error('Failed to stop listening', e);
    }
  }

  /// Cancel listening
  Future<void> cancelListening() async {
    try {
      await _speech.cancel();
    } catch (e) {
      AppLogger.error('Failed to cancel listening', e);
    }
  }

  /// Check if currently listening
  bool get isListening => _speech.isListening;

  /// Check if available
  bool get isAvailable => _isInitialized;

  /// Dispose
  Future<void> dispose() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
  }
}
