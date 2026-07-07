import 'package:flutter/foundation.dart';

/// Simple error logger for development and production
/// Logs errors locally and can be extended to send to backend
class ErrorLogger {
  /// Log an error with context
  static void logError(
    dynamic error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final errorType = fatal ? 'FATAL' : 'ERROR';
    
    debugPrint('[$timestamp] [$errorType] ${context ?? 'Unknown context'}');
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace:\n$stackTrace');
    }
    
    // TODO: In production, send errors to your backend API
    // await _sendErrorToBackend(error, stackTrace, context, fatal);
  }

  /// Log Flutter framework errors
  static void logFlutterError(FlutterErrorDetails details) {
    debugPrint('[FLUTTER ERROR] ${details.exception}');
    debugPrint('Stack trace:\n${details.stack}');
    
    // TODO: Send to backend if needed
  }

  /// Log a message for debugging
  static void log(String message) {
    debugPrint('[LOG] $message');
  }
}
