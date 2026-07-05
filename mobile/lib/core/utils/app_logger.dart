import 'package:logger/logger.dart';

/// Centralized logger for the RepSense app
/// Provides consistent logging across all features
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  /// Simple logger for production - less verbose
  static final Logger _simpleLogger = Logger(
    printer: SimplePrinter(colors: true, printTime: true),
  );

  /// Get logger instance based on environment
  static Logger get instance {
    // Use simple logger in production, pretty logger in debug
    return const bool.fromEnvironment('dart.vm.product')
        ? _simpleLogger
        : _logger;
  }

  // Convenience methods
  static void debug(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.d(message, error: error, stackTrace: stackTrace);
  }

  static void info(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.i(message, error: error, stackTrace: stackTrace);
  }

  static void warning(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.w(message, error: error, stackTrace: stackTrace);
  }

  static void error(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.e(message, error: error, stackTrace: stackTrace);
  }

  static void wtf(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    instance.f(message, error: error, stackTrace: stackTrace);
  }
}
