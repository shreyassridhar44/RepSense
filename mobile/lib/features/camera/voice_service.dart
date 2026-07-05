import 'package:flutter_tts/flutter_tts.dart';
import '../../core/utils/app_logger.dart';

/// Service for text-to-speech voice guidance
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();
  bool _isEnabled = true;
  bool _isInitialized = false;
  String? _pendingText;

  bool get isEnabled => _isEnabled;

  /// Initialize TTS
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      AppLogger.info('🔊 Initializing voice service');

      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5); // Slower for clarity
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      // Set completion handler
      _tts.setCompletionHandler(() {
        // If there's pending text, speak it
        if (_pendingText != null) {
          final text = _pendingText;
          _pendingText = null;
          speak(text!);
        }
      });

      _isInitialized = true;
      AppLogger.info('✅ Voice service initialized');
    } catch (e, stack) {
      AppLogger.warning('⚠️ Voice service initialization failed (TTS may not be available)', e, stack);
      // Silently disable voice on devices without TTS
      _isEnabled = false;
      _isInitialized = false;
    }
  }

  /// Speak text (with queue management)
  Future<void> speak(String text) async {
    if (!_isEnabled || !_isInitialized || text.isEmpty) return;

    try {
      // Check if currently speaking
      final isSpeaking = await _tts.awaitSpeakCompletion(false);
      
      if (isSpeaking == 1) {
        // Already speaking, queue this (max 1 item - discard if queue full)
        _pendingText = text;
        AppLogger.debug('🔊 Voice queued: $text');
      } else {
        // Not speaking, speak immediately
        await _tts.speak(text);
        AppLogger.debug('🔊 Voice speaking: $text');
      }
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to speak', e, stack);
    }
  }

  /// Stop current speech
  Future<void> stop() async {
    if (!_isInitialized) return;

    try {
      await _tts.stop();
      _pendingText = null;
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to stop speech', e, stack);
    }
  }

  /// Set enabled state
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
    if (!enabled) {
      stop();
    }
    AppLogger.info('🔊 Voice ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Dispose resources
  Future<void> dispose() async {
    try {
      await stop();
      _isInitialized = false;
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to dispose voice service', e, stack);
    }
  }
}
