import 'package:collection/collection.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/chat_models.dart';
import '../../../data/models/progress_models.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/supabase/supabase_service.dart';

/// Builds CoachContext from Supabase data
class CoachContextBuilder {
  final SupabaseService _supabase;
  final ProgressRepository _progressRepo;

  CoachContextBuilder({
    SupabaseService? supabase,
    ProgressRepository? progressRepo,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _progressRepo = progressRepo ?? ProgressRepository();

  /// Build complete coach context for a user
  Future<CoachContext> build(String userId) async {
    try {
      AppLogger.info('🧠 Building coach context for user: $userId');

      // Fetch data in parallel
      final results = await Future.wait([
        _supabase.getProfile(userId),
        _supabase.getWorkoutsInLastDays(userId, 7),
        _progressRepo.getAllWorkoutsWithExercise(userId),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final last7Workouts = results[1] as List<Map<String, dynamic>>;
      final allWorkouts = results[2] as List<WorkoutWithExercise>;

      // Extract profile data
      final displayName = profile?['display_name'] as String?;
      final trainingExperience = profile?['training_experience'] as String?;
      final goalsJson = profile?['goals'] as List<dynamic>?;
      final goals = goalsJson?.map((g) => g.toString()).toList() ?? [];
      final heightCm = (profile?['height_cm'] as num?)?.toDouble();
      final weightKg = (profile?['weight_kg'] as num?)?.toDouble();

      // Compute derived fields
      final totalWorkouts = allWorkouts.length;

      // Average form score last 7 days (excluding 0.0)
      final validScores = last7Workouts
          .map((w) => (w['avg_form_score'] as num?)?.toDouble() ?? 0.0)
          .where((score) => score > 0.0)
          .toList();
      final avgFormScoreLast7Days = validScores.isNotEmpty
          ? validScores.average * 100
          : null;

      // Most trained exercise
      final exerciseCounts = <String, int>{};
      for (final workout in allWorkouts) {
        exerciseCounts[workout.exerciseName] =
            (exerciseCounts[workout.exerciseName] ?? 0) + 1;
      }
      final mostTrainedExercise = exerciseCounts.isNotEmpty
          ? exerciseCounts.entries
              .reduce((a, b) => a.value > b.value ? a : b)
              .key
          : null;

      // Weakest muscle group (score < 50)
      final weakestMuscleGroup = await _computeWeakestMuscleGroup(allWorkouts);

      // Recent issues (top 3 by frequency from last 3 workouts)
      final recentIssues = await _computeRecentIssues(userId, allWorkouts);

      // Recent workouts (last 5)
      final recentWorkouts = await _computeRecentWorkouts(userId, allWorkouts);

      // Current streak
      final currentStreakDays = _computeCurrentStreak(allWorkouts);

      final context = CoachContext(
        displayName: displayName,
        trainingExperience: trainingExperience,
        goals: goals,
        heightCm: heightCm,
        weightKg: weightKg,
        totalWorkouts: totalWorkouts,
        currentStreakDays: currentStreakDays,
        avgFormScoreLast7Days: avgFormScoreLast7Days,
        mostTrainedExercise: mostTrainedExercise,
        weakestMuscleGroup: weakestMuscleGroup,
        recentIssues: recentIssues,
        recentWorkouts: recentWorkouts,
      );

      AppLogger.info('✅ Coach context built successfully');
      return context;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to build coach context', e, stack);
      // Return partial context - better than nothing
      return const CoachContext();
    }
  }

  /// Compute weakest muscle group (score < 50)
  Future<String?> _computeWeakestMuscleGroup(
    List<WorkoutWithExercise> workouts,
  ) async {
    try {
      if (workouts.isEmpty) return null;

      // Group by muscle and compute average scores
      final byMuscle = groupBy<WorkoutWithExercise, String>(
        workouts,
        (w) => w.muscleGroup,
      );

      final muscleScores = byMuscle.map(
        (muscle, workouts) {
          final avgScore = workouts.map((w) => w.avgFormScore).average * 100;
          return MapEntry(muscle, avgScore);
        },
      );

      // Find muscle with lowest score < 50
      final weakest = muscleScores.entries
          .where((e) => e.value < 50)
          .sorted((a, b) => a.value.compareTo(b.value))
          .firstOrNull;

      return weakest?.key;
    } catch (e) {
      AppLogger.debug('Failed to compute weakest muscle group');
      return null;
    }
  }

  /// Compute recent issues from last 3 workouts
  Future<List<String>> _computeRecentIssues(
    String userId,
    List<WorkoutWithExercise> workouts,
  ) async {
    try {
      if (workouts.isEmpty) return [];

      // Get last 3 workout IDs
      final last3 = workouts.take(3).map((w) => w.id).toList();

      // Fetch rep analyses
      final analyses = await _progressRepo.getRepAnalysesForWorkouts(last3);

      // Collect all problem strings
      final problems = <String>[];
      for (final workoutAnalyses in analyses.values) {
        for (final analysis in workoutAnalyses) {
          final issues = analysis['issues'] as List<dynamic>?;
          if (issues != null) {
            for (final issue in issues) {
              final problem = issue['problem'] as String?;
              if (problem != null) {
                problems.add(problem);
              }
            }
          }
        }
      }

      // Count frequency and return top 3
      final frequency = <String, int>{};
      for (final problem in problems) {
        frequency[problem] = (frequency[problem] ?? 0) + 1;
      }

      return frequency.entries
          .sorted((a, b) => b.value.compareTo(a.value))
          .take(3)
          .map((e) => e.key)
          .toList();
    } catch (e) {
      AppLogger.debug('Failed to compute recent issues');
      return [];
    }
  }

  /// Compute recent workouts (last 5)
  Future<List<RecentWorkoutContext>> _computeRecentWorkouts(
    String userId,
    List<WorkoutWithExercise> workouts,
  ) async {
    try {
      if (workouts.isEmpty) return [];

      final last5 = workouts.take(5);

      // Fetch rep analyses for these workouts
      final workoutIds = last5.map((w) => w.id).toList();
      final analyses = await _progressRepo.getRepAnalysesForWorkouts(workoutIds);

      return last5.map((workout) {
        // Find most frequent problem in this workout
        String? topIssue;
        final workoutAnalyses = analyses[workout.id];
        if (workoutAnalyses != null) {
          final problems = <String>[];
          for (final analysis in workoutAnalyses) {
            final issues = analysis['issues'] as List<dynamic>?;
            if (issues != null) {
              for (final issue in issues) {
                final problem = issue['problem'] as String?;
                if (problem != null) {
                  problems.add(problem);
                }
              }
            }
          }

          if (problems.isNotEmpty) {
            final frequency = <String, int>{};
            for (final problem in problems) {
              frequency[problem] = (frequency[problem] ?? 0) + 1;
            }
            topIssue = frequency.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key;
          }
        }

        return RecentWorkoutContext(
          exerciseName: workout.exerciseName,
          date: workout.createdAt,
          avgFormScore: workout.avgFormScore * 100,
          totalReps: workout.totalReps,
          topIssue: topIssue,
        );
      }).toList();
    } catch (e) {
      AppLogger.debug('Failed to compute recent workouts');
      return [];
    }
  }

  /// Compute current streak
  int _computeCurrentStreak(List<WorkoutWithExercise> workouts) {
    try {
      if (workouts.isEmpty) return 0;

      final activeDays = workouts.map((w) => _dateKey(w.createdAt)).toSet();
      int streak = 0;
      final now = DateTime.now();

      for (int i = 0; i < 365; i++) {
        final date = now.subtract(Duration(days: i));
        final key = _dateKey(date);

        if (activeDays.contains(key)) {
          streak++;
        } else if (i > 0) {
          // Allow one grace day for today
          break;
        }
      }

      return streak;
    } catch (e) {
      AppLogger.debug('Failed to compute streak');
      return 0;
    }
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
