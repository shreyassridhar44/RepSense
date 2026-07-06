import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/progress_models.dart';
import '../supabase/supabase_service.dart';

/// Repository for fetching progress-related data from Supabase
/// Handles all database queries with caching and error handling
class ProgressRepository {
  final SupabaseService _supabase;

  // Cache for workout data (keyed by userId)
  final Map<String, List<WorkoutWithExercise>> _workoutCache = {};
  DateTime? _lastCacheFetch;
  static const _cacheDuration = Duration(minutes: 5);

  ProgressRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get all workouts with exercise details for a user
  /// Returns cached data if available and fresh
  Future<List<WorkoutWithExercise>> getAllWorkoutsWithExercise(String userId) async {
    try {
      // Check cache first
      if (_workoutCache.containsKey(userId) &&
          _lastCacheFetch != null &&
          DateTime.now().difference(_lastCacheFetch!) < _cacheDuration) {
        AppLogger.debug('📦 Returning cached workout data');
        return _workoutCache[userId]!;
      }

      AppLogger.info('📊 Fetching all workouts with exercises for user: $userId');

      final response = await _supabase.client
          .from('workouts')
          .select('*, exercises(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final workouts = (response as List<dynamic>)
          .map((json) => WorkoutWithExercise.fromJson(json as Map<String, dynamic>))
          .toList();

      // Update cache
      _workoutCache[userId] = workouts;
      _lastCacheFetch = DateTime.now();

      AppLogger.info('✅ Fetched ${workouts.length} workouts');
      return workouts;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch workouts with exercises', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  /// Get rep analyses for specific workouts
  /// Used for detailed form scoring breakdowns
  Future<Map<String, List<Map<String, dynamic>>>> getRepAnalysesForWorkouts(
    List<String> workoutIds,
  ) async {
    if (workoutIds.isEmpty) {
      return {};
    }

    try {
      AppLogger.info('📊 Fetching rep analyses for ${workoutIds.length} workouts');

      final response = await _supabase.client
          .from('rep_analyses')
          .select('*')
          .inFilter('workout_id', workoutIds)
          .order('workout_id')
          .order('rep_index');

      final analyses = response as List<dynamic>;

      // Group by workout_id
      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final analysis in analyses) {
        final workoutId = analysis['workout_id'] as String;
        grouped.putIfAbsent(workoutId, () => []);
        grouped[workoutId]!.add(analysis as Map<String, dynamic>);
      }

      AppLogger.info('✅ Fetched rep analyses for ${grouped.length} workouts');
      return grouped;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch rep analyses', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  /// Get user profile for personal stats
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      AppLogger.debug('👤 Fetching profile for progress: $userId');
      return await _supabase.getProfile(userId);
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch profile', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  /// Clear cache (call after new workout is saved)
  void clearCache() {
    AppLogger.debug('🗑️ Clearing progress cache');
    _workoutCache.clear();
    _lastCacheFetch = null;
  }

  /// Force refresh (bypasses cache)
  Future<List<WorkoutWithExercise>> refreshWorkouts(String userId) async {
    clearCache();
    return getAllWorkoutsWithExercise(userId);
  }
}
