import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Deep linking handler for RepSense
/// Supports:
/// - App Links (Android): https://repsense.app/*
/// - Universal Links (iOS): https://repsense.app/*
/// - Custom scheme: repsense://*
class DeepLinkHandler {
  static StreamSubscription? _linkSubscription;
  static final AppLinks _appLinks = AppLinks();

  /// Initialize deep linking
  static Future<void> initialize(GoRouter router) async {
    try {
      // Handle initial link (app launched via deep link)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 Initial deep link: $initialUri');
        _handleDeepLink(initialUri, router);
      }

      // Listen for subsequent links (app already running)
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            debugPrint('🔗 Deep link received: $uri');
            _handleDeepLink(uri, router);
          }
        },
        onError: (err) {
          debugPrint('⚠️ Deep link error: $err');
        },
      );

      debugPrint('✅ Deep linking initialized');
    } catch (e) {
      debugPrint('⚠️ Deep linking initialization failed: $e');
    }
  }

  /// Dispose deep link listener
  static void dispose() {
    _linkSubscription?.cancel();
  }

  /// Handle a deep link
  static void _handleDeepLink(Uri uri, GoRouter router) {
    // Get the path from URI
    String path = uri.path;
    if (path.isEmpty) path = '/';

    // Add query parameters if present
    if (uri.hasQuery) {
      path += '?${uri.query}';
    }

    debugPrint('📍 Navigating to: $path');

    try {
      router.go(path);
    } catch (e) {
      debugPrint('⚠️ Navigation failed: $e');
      // Fallback to home if path is invalid
      router.go('/');
    }
  }
}

// ============================================================================
// Supported Deep Links
// ============================================================================
// 
// Home:
//   repsense://home
//   https://repsense.app/home
// 
// Workout:
//   repsense://workouts/{workoutId}
//   https://repsense.app/workouts/{workoutId}
// 
// Exercise:
//   repsense://exercises/{exerciseId}
//   https://repsense.app/exercises/{exerciseId}
// 
// Progress:
//   repsense://progress
//   https://repsense.app/progress
// 
// AI Coach:
//   repsense://coach
//   https://repsense.app/coach
// 
// Profile:
//   repsense://profile
//   https://repsense.app/profile
// 
// Achievements:
//   repsense://achievements
//   https://repsense.app/achievements
// 
// Sharing (e.g., workout share):
//   repsense://share?code=ABC123
//   https://repsense.app/share?code=ABC123
// 
// ============================================================================
