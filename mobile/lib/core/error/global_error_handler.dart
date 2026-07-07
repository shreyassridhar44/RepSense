import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../monitoring/error_logger.dart';
import 'friendly_error_screen.dart';

/// Global error handler for the entire app
/// Catches all Flutter framework errors, Dart async errors, and provider errors
class GlobalErrorHandler {
  static void initialize() {
    // 1. Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Log errors
      ErrorLogger.logFlutterError(details);

      // In debug: show red error screen (default Flutter behavior)
      // In release: show a friendly error screen
      if (kReleaseMode) {
        // Don't use the default red screen in production
        FlutterError.presentError(details);
      } else {
        FlutterError.dumpErrorToConsole(details);
      }
    };

    // 2. Dart async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      ErrorLogger.logError(error, stack, fatal: true);
      return true; // Prevent default crash
    };

    // Note: Riverpod observer is added in ProviderScope in main.dart
  }

  /// Create a friendly error widget for release mode
  static Widget createFriendlyErrorWidget(FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FriendlyErrorScreen(details: details),
    );
  }
}

/// Riverpod observer that logs provider errors
class RepSenseProviderObserver extends ProviderObserver {
  @override
  void providerDidFail(
    ProviderBase provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    ErrorLogger.logError(
      error,
      stackTrace,
      context: 'Provider: ${provider.name ?? provider.runtimeType}',
    );
  }

  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (kDebugMode) {
      // Log provider updates in debug mode for debugging
      debugPrint('Provider updated: ${provider.name ?? provider.runtimeType}');
    }
  }
}
