import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';

/// Offline cache service for storing data locally
/// Allows app to function in offline mode for read operations
class CacheService {
  static const String _exercisesBox = 'exercises_cache';
  static const String _workoutsBox = 'workouts_cache';
  static const String _progressBox = 'progress_cache';
  static const String _profileBox = 'profile_cache';

  /// Initialize cache boxes
  static Future<void> initialize() async {
    try {
      await Hive.openBox(_exercisesBox);
      await Hive.openBox(_workoutsBox);
      await Hive.openBox(_progressBox);
      await Hive.openBox(_profileBox);
      debugPrint('✅ Cache service initialized');
    } catch (e) {
      debugPrint('⚠️ Cache initialization failed: $e');
    }
  }

  // ==========================================================================
  // Exercises Cache
  // ==========================================================================

  static Future<void> cacheExercises(List<Map<String, dynamic>> exercises) async {
    try {
      if (!Hive.isBoxOpen(_exercisesBox)) await Hive.openBox(_exercisesBox);
      final box = Hive.box(_exercisesBox);
      await box.put('all_exercises', exercises);
      await box.put('last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Failed to cache exercises: $e');
    }
  }

  static List<Map<String, dynamic>>? getCachedExercises() {
    try {
      if (!Hive.isBoxOpen(_exercisesBox)) return null;
      final box = Hive.box(_exercisesBox);
      final cached = box.get('all_exercises');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached exercises: $e');
    }
    return null;
  }

  static Future<void> cacheExercise(String id, Map<String, dynamic> exercise) async {
    try {
      final box = Hive.box(_exercisesBox);
      await box.put('exercise_$id', exercise);
    } catch (e) {
      debugPrint('⚠️ Failed to cache exercise: $e');
    }
  }

  static Map<String, dynamic>? getCachedExercise(String id) {
    try {
      final box = Hive.box(_exercisesBox);
      final cached = box.get('exercise_$id');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached exercise: $e');
    }
    return null;
  }

  // ==========================================================================
  // Workouts Cache
  // ==========================================================================

  static Future<void> cacheWorkouts(List<Map<String, dynamic>> workouts) async {
    try {
      final box = Hive.box(_workoutsBox);
      await box.put('recent_workouts', workouts);
      await box.put('last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Failed to cache workouts: $e');
    }
  }

  static List<Map<String, dynamic>>? getCachedWorkouts() {
    try {
      final box = Hive.box(_workoutsBox);
      final cached = box.get('recent_workouts');
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached workouts: $e');
    }
    return null;
  }

  // ==========================================================================
  // Progress Cache
  // ==========================================================================

  static Future<void> cacheProgress(Map<String, dynamic> progress) async {
    try {
      final box = Hive.box(_progressBox);
      await box.put('user_progress', progress);
      await box.put('last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Failed to cache progress: $e');
    }
  }

  static Map<String, dynamic>? getCachedProgress() {
    try {
      final box = Hive.box(_progressBox);
      final cached = box.get('user_progress');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached progress: $e');
    }
    return null;
  }

  // ==========================================================================
  // Profile Cache
  // ==========================================================================

  static Future<void> cacheProfile(Map<String, dynamic> profile) async {
    try {
      final box = Hive.box(_profileBox);
      await box.put('user_profile', profile);
      await box.put('last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('⚠️ Failed to cache profile: $e');
    }
  }

  static Map<String, dynamic>? getCachedProfile() {
    try {
      final box = Hive.box(_profileBox);
      final cached = box.get('user_profile');
      if (cached != null) {
        return Map<String, dynamic>.from(cached);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get cached profile: $e');
    }
    return null;
  }

  // ==========================================================================
  // Cache Management
  // ==========================================================================

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      await Hive.box(_exercisesBox).clear();
      await Hive.box(_workoutsBox).clear();
      await Hive.box(_progressBox).clear();
      await Hive.box(_profileBox).clear();
      debugPrint('✅ All cache cleared');
    } catch (e) {
      debugPrint('⚠️ Failed to clear cache: $e');
    }
  }

  /// Get last sync time for a box
  static DateTime? getLastSync(String boxName) {
    try {
      final box = Hive.box(boxName);
      final lastSync = box.get('last_sync');
      if (lastSync != null) {
        return DateTime.parse(lastSync);
      }
    } catch (e) {
      debugPrint('⚠️ Failed to get last sync: $e');
    }
    return null;
  }

  /// Check if cache is stale (older than 1 hour)
  static bool isCacheStale(String boxName) {
    final lastSync = getLastSync(boxName);
    if (lastSync == null) return true;
    return DateTime.now().difference(lastSync).inHours > 1;
  }
}
