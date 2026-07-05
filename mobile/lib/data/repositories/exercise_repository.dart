import '../../core/utils/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_personal_stats.dart';
import '../models/exercise_model.dart';
import '../supabase/supabase_service.dart';

class ExerciseRepository {
  final SupabaseService _service = SupabaseService.instance;

  // Get all exercises with user's favorite status
  Future<List<Exercise>> getAllExercises(String userId) async {
    try {
      AppLogger.info('📊 Fetching all exercises for user: $userId');

      // Fetch exercises and favorites in parallel
      final results = await Future.wait([
        _service.getExercises(),
        _service.getFavoriteExerciseIds(userId),
      ]);

      final exercisesData = results[0] as List<Map<String, dynamic>>;
      final favoriteIds = results[1] as List<String>;

      final exercises = exercisesData.map((json) {
        final isFavorited = favoriteIds.contains(json['id'] as String);
        return ExerciseModel.fromJson(json, isFavorited: isFavorited);
      }).toList();

      AppLogger.info('✅ Fetched ${exercises.length} exercises (${favoriteIds.length} favorited)');
      return exercises;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch exercises', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  // Get single exercise by ID
  Future<Exercise> getExerciseById(String id, String userId) async {
    try {
      AppLogger.info('📊 Fetching exercise: $id');

      final results = await Future.wait([
        _service.getExerciseById(id),
        _service.getFavoriteExerciseIds(userId),
      ]);

      final exerciseData = results[0] as Map<String, dynamic>?;
      final favoriteIds = results[1] as List<String>;

      if (exerciseData == null) {
        throw AppException(
          message: 'Exercise not found',
          code: 'NOT_FOUND',
        );
      }

      final isFavorited = favoriteIds.contains(id);
      final exercise = ExerciseModel.fromJson(exerciseData, isFavorited: isFavorited);

      AppLogger.info('✅ Fetched exercise: ${exercise.name}');
      return exercise;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch exercise: $id', e, stack);
      if (e is AppException) rethrow;
      throw AppException.fromSupabase(e);
    }
  }

  // Add favorite
  Future<void> addFavorite(String userId, String exerciseId) async {
    try {
      AppLogger.info('⭐ Adding favorite: $exerciseId');
      await _service.addFavorite(userId, exerciseId);
      AppLogger.info('✅ Favorite added');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to add favorite', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  // Remove favorite
  Future<void> removeFavorite(String userId, String exerciseId) async {
    try {
      AppLogger.info('⭐ Removing favorite: $exerciseId');
      await _service.removeFavorite(userId, exerciseId);
      AppLogger.info('✅ Favorite removed');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to remove favorite', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  // Search exercises
  Future<List<Exercise>> searchExercises(String query, String userId) async {
    try {
      AppLogger.info('🔍 Searching exercises: "$query"');

      // Get all exercises first
      final exercises = await getAllExercises(userId);

      if (query.isEmpty) return exercises;

      final lowerQuery = query.toLowerCase();

      // Filter by name or muscle groups
      final results = exercises.where((exercise) {
        final nameMatch = exercise.name.toLowerCase().contains(lowerQuery);
        final muscleMatch = exercise.muscleGroups
            .any((muscle) => muscle.toLowerCase().contains(lowerQuery));
        final primaryMatch = exercise.primaryMuscle?.toLowerCase().contains(lowerQuery) ?? false;
        
        return nameMatch || muscleMatch || primaryMatch;
      }).toList();

      AppLogger.info('✅ Found ${results.length} exercises matching "$query"');
      return results;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to search exercises', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  // Get personal stats for an exercise
  Future<ExercisePersonalStats> getPersonalStats(String userId, String exerciseId) async {
    try {
      AppLogger.info('📊 Fetching personal stats for exercise: $exerciseId');

      final workouts = await _service.getWorkoutsForExercise(userId, exerciseId);

      if (workouts.isEmpty) {
        AppLogger.info('ℹ️ No workout history for this exercise');
        return const ExercisePersonalStats();
      }

      // Calculate stats
      final totalSessions = workouts.length;
      final totalReps = workouts.fold<int>(
        0,
        (sum, w) => sum + (w['total_reps'] as int? ?? 0),
      );

      // Filter out 0.0 scores for average
      final validScores = workouts
          .map((w) => (w['avg_form_score'] as num?)?.toDouble() ?? 0.0)
          .where((score) => score > 0.0)
          .toList();

      final avgFormScore = validScores.isEmpty
          ? 0.0
          : validScores.reduce((a, b) => a + b) / validScores.length;

      final bestFormScore = validScores.isEmpty
          ? 0.0
          : validScores.reduce((a, b) => a > b ? a : b);

      final bestRepsInSession = workouts.fold<int>(
        0,
        (max, w) {
          final reps = w['total_reps'] as int? ?? 0;
          return reps > max ? reps : max;
        },
      );

      final lastPerformed = workouts.isNotEmpty
          ? DateTime.parse(workouts.first['created_at'] as String)
          : null;

      // Calculate improvement trend
      double improvementTrend = 0.0;
      if (totalSessions >= 6) {
        final first3Scores = validScores.take(3).toList();
        final last3Scores = validScores.skip(validScores.length - 3).take(3).toList();

        if (first3Scores.length == 3 && last3Scores.length == 3) {
          final first3Avg = first3Scores.reduce((a, b) => a + b) / 3;
          final last3Avg = last3Scores.reduce((a, b) => a + b) / 3;
          improvementTrend = last3Avg - first3Avg;
        }
      }

      final stats = ExercisePersonalStats(
        totalSessions: totalSessions,
        totalReps: totalReps,
        avgFormScore: double.parse(avgFormScore.toStringAsFixed(1)),
        bestFormScore: double.parse(bestFormScore.toStringAsFixed(1)),
        bestRepsInSession: bestRepsInSession,
        lastPerformed: lastPerformed,
        improvementTrend: double.parse(improvementTrend.toStringAsFixed(1)),
      );

      AppLogger.info('✅ Personal stats calculated: $totalSessions sessions, $totalReps reps');
      return stats;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch personal stats', e, stack);
      throw AppException.fromSupabase(e);
    }
  }
}
