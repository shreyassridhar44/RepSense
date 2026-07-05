import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';
import 'home_state.dart';
import 'models/achievement.dart';
import 'models/personal_best.dart';
import 'models/workout_suggestion.dart';
import 'models/workout_summary.dart';

class HomeNotifier extends StateNotifier<HomeState> {
  HomeNotifier() : super(const HomeState());

  final _service = SupabaseService.instance;
  bool _isLoading = false;

  Future<void> load() async {
    if (_isLoading) return;
    _isLoading = true;

    state = state.copyWith(status: HomeStatus.loading);
    AppLogger.info('🏠 Loading home data...');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _service.getProfile(user.id),
        _service.getAllWorkouts(user.id),
        _service.getAchievements(user.id),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final workoutsData = results[1] as List<Map<String, dynamic>>;
      final achievementsData = results[2] as List<Map<String, dynamic>>;

      // Process workouts
      final workouts = _processWorkouts(workoutsData);

      // Compute all metrics
      final displayName = profile?['display_name'] as String? ?? 'User';
      final streak = _calculateStreak(workouts);
      final consistency = _calculateWeeklyConsistency(workouts);
      final caloriesToday = _calculateTodayCalories(workouts);
      final qualityScore = _calculateMovementQualityScore(workouts);
      final stabilityScore = _calculateStabilityScore(workouts);
      final symmetryScore = _calculateSymmetryScore(workouts);
      final recentWorkouts = workouts.take(5).toList();
      final achievements = achievementsData.map((json) => Achievement.fromJson(json)).toList();
      final recentAchievements = achievements.take(4).toList();
      final personalBests = _calculatePersonalBests(workouts);
      final weeklyInsight = _generateWeeklyInsight(
        streak: streak,
        consistency: consistency,
        qualityScore: qualityScore,
        workouts: workouts,
      );
      final suggestion = _generateWorkoutSuggestion(workouts);

      state = HomeState(
        status: HomeStatus.loaded,
        displayName: displayName,
        currentStreakDays: streak,
        weeklyConsistencyPct: consistency,
        totalCaloriesToday: caloriesToday,
        movementQualityScore: qualityScore,
        stabilityScore: stabilityScore,
        symmetryScore: symmetryScore,
        recentWorkouts: recentWorkouts,
        recentAchievements: recentAchievements,
        personalBests: personalBests,
        weeklyInsight: weeklyInsight,
        todayWorkoutSuggestion: suggestion,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Home data loaded successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to load home data', e, stack);
      state = state.copyWith(
        status: HomeStatus.error,
        errorMessage: e.toString(),
      );
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    if (_isLoading) return;
    
    state = state.copyWith(isRefreshing: true);
    AppLogger.info('🔄 Refreshing home data...');

    try {
      final user = _service.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _service.getProfile(user.id),
        _service.getAllWorkouts(user.id),
        _service.getAchievements(user.id),
      ]);

      final profile = results[0] as Map<String, dynamic>?;
      final workoutsData = results[1] as List<Map<String, dynamic>>;
      final achievementsData = results[2] as List<Map<String, dynamic>>;

      // Process workouts
      final workouts = _processWorkouts(workoutsData);

      // Compute all metrics
      final displayName = profile?['display_name'] as String? ?? 'User';
      final streak = _calculateStreak(workouts);
      final consistency = _calculateWeeklyConsistency(workouts);
      final caloriesToday = _calculateTodayCalories(workouts);
      final qualityScore = _calculateMovementQualityScore(workouts);
      final stabilityScore = _calculateStabilityScore(workouts);
      final symmetryScore = _calculateSymmetryScore(workouts);
      final recentWorkouts = workouts.take(5).toList();
      final achievements = achievementsData.map((json) => Achievement.fromJson(json)).toList();
      final recentAchievements = achievements.take(4).toList();
      final personalBests = _calculatePersonalBests(workouts);
      final weeklyInsight = _generateWeeklyInsight(
        streak: streak,
        consistency: consistency,
        qualityScore: qualityScore,
        workouts: workouts,
      );
      final suggestion = _generateWorkoutSuggestion(workouts);

      state = state.copyWith(
        status: HomeStatus.loaded,
        isRefreshing: false,
        displayName: displayName,
        currentStreakDays: streak,
        weeklyConsistencyPct: consistency,
        totalCaloriesToday: caloriesToday,
        movementQualityScore: qualityScore,
        stabilityScore: stabilityScore,
        symmetryScore: symmetryScore,
        recentWorkouts: recentWorkouts,
        recentAchievements: recentAchievements,
        personalBests: personalBests,
        weeklyInsight: weeklyInsight,
        todayWorkoutSuggestion: suggestion,
        lastUpdated: DateTime.now(),
      );

      AppLogger.info('✅ Home data refreshed successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to refresh home data', e, stack);
      state = state.copyWith(
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(
      status: HomeStatus.loaded,
      errorMessage: null,
    );
  }

  // ========== DATA PROCESSING ==========

  List<WorkoutSummary> _processWorkouts(List<Map<String, dynamic>> data) {
    return data.map((json) {
      // Extract exercise name from nested exercises object
      String exerciseName = 'Unknown Exercise';
      if (json['exercises'] != null) {
        final exercise = json['exercises'] as Map<String, dynamic>;
        exerciseName = exercise['name'] as String? ?? 'Unknown Exercise';
      }

      return WorkoutSummary(
        id: json['id'] as String,
        exerciseId: json['exercise_id'] as String,
        exerciseName: exerciseName,
        totalReps: json['total_reps'] as int? ?? 0,
        correctReps: json['correct_reps'] as int? ?? 0,
        avgFormScore: (json['avg_form_score'] as num?)?.toDouble() ?? 0.0,
        durationSeconds: json['duration_seconds'] as int? ?? 0,
        calories: (json['calories'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );
    }).toList();
  }

  // ========== STREAK CALCULATION ==========

  int _calculateStreak(List<WorkoutSummary> workouts) {
    if (workouts.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // Group workouts by calendar date (local timezone)
    final workoutDates = <DateTime>{};
    for (final workout in workouts) {
      final workoutDate = DateTime(
        workout.createdAt.year,
        workout.createdAt.month,
        workout.createdAt.day,
      );
      workoutDates.add(workoutDate);
    }

    // Sort dates descending
    final sortedDates = workoutDates.toList()..sort((a, b) => b.compareTo(a));

    // Check if streak is alive (today or yesterday has a workout)
    final latestDate = sortedDates.first;
    if (latestDate != today && latestDate != yesterday) {
      return 0;
    }

    // Count consecutive days
    int streak = 0;
    DateTime checkDate = today;

    for (final date in sortedDates) {
      if (date == checkDate || date == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  // ========== WEEKLY CONSISTENCY ==========

  double _calculateWeeklyConsistency(List<WorkoutSummary> workouts) {
    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    // Get workouts from last 7 days
    final recentWorkouts = workouts.where((w) => w.createdAt.isAfter(sevenDaysAgo)).toList();

    if (recentWorkouts.isEmpty) return 0.0;

    // Group by calendar date
    final workoutDates = <DateTime>{};
    for (final workout in recentWorkouts) {
      final workoutDate = DateTime(
        workout.createdAt.year,
        workout.createdAt.month,
        workout.createdAt.day,
      );
      workoutDates.add(workoutDate);
    }

    final daysWorkedOut = workoutDates.length;
    return (daysWorkedOut / 7.0) * 100.0;
  }

  // ========== TODAY'S CALORIES ==========

  double _calculateTodayCalories(List<WorkoutSummary> workouts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final todayWorkouts = workouts.where((w) {
      final workoutDate = DateTime(
        w.createdAt.year,
        w.createdAt.month,
        w.createdAt.day,
      );
      return workoutDate == today;
    }).toList();

    double totalCalories = 0.0;
    for (final workout in todayWorkouts) {
      if (workout.calories != null && workout.calories! > 0) {
        totalCalories += workout.calories!;
      } else {
        // Estimate: 0.35 calories per rep
        totalCalories += workout.totalReps * 0.35;
      }
    }

    return totalCalories;
  }

  // ========== MOVEMENT QUALITY SCORES ==========

  double _calculateMovementQualityScore(List<WorkoutSummary> workouts) {
    final last7Workouts = workouts.take(7).where((w) => w.avgFormScore > 0.0).toList();

    if (last7Workouts.isEmpty) return 0.0;

    final sum = last7Workouts.fold<double>(0.0, (sum, w) => sum + w.avgFormScore);
    return double.parse((sum / last7Workouts.length).toStringAsFixed(1));
  }

  double _calculateStabilityScore(List<WorkoutSummary> workouts) {
    // For now, use movement quality * 0.95 as fallback
    // In future modules, this will pull from rep_analyses.scores['stability']
    final qualityScore = _calculateMovementQualityScore(workouts);
    return double.parse((qualityScore * 0.95).toStringAsFixed(1));
  }

  double _calculateSymmetryScore(List<WorkoutSummary> workouts) {
    // For now, use movement quality * 0.93 as fallback
    // In future modules, this will pull from rep_analyses.scores['symmetry']
    final qualityScore = _calculateMovementQualityScore(workouts);
    return double.parse((qualityScore * 0.93).toStringAsFixed(1));
  }

  // ========== PERSONAL BESTS ==========

  Map<String, PersonalBest> _calculatePersonalBests(List<WorkoutSummary> workouts) {
    final Map<String, PersonalBest> bests = {};

    // Group by exercise
    final exerciseGroups = <String, List<WorkoutSummary>>{};
    for (final workout in workouts) {
      exerciseGroups.putIfAbsent(workout.exerciseId, () => []).add(workout);
    }

    // Find best for each exercise
    for (final entry in exerciseGroups.entries) {
      final exerciseWorkouts = entry.value;
      
      // Find highest reps
      final bestRepsWorkout = exerciseWorkouts.reduce((a, b) => 
        a.totalReps > b.totalReps ? a : b
      );
      
      // Find highest form score
      final bestScoreWorkout = exerciseWorkouts.reduce((a, b) => 
        a.avgFormScore > b.avgFormScore ? a : b
      );

      // Use the one with better score as the overall best
      final bestWorkout = bestScoreWorkout.avgFormScore > bestRepsWorkout.avgFormScore
          ? bestScoreWorkout
          : bestRepsWorkout;

      bests[entry.key] = PersonalBest(
        exerciseId: bestWorkout.exerciseId,
        exerciseName: bestWorkout.exerciseName,
        bestReps: bestRepsWorkout.totalReps,
        bestFormScore: bestScoreWorkout.avgFormScore,
        achievedAt: bestWorkout.createdAt,
      );
    }

    return bests;
  }

  // ========== WEEKLY INSIGHT ==========

  String _generateWeeklyInsight({
    required int streak,
    required double consistency,
    required double qualityScore,
    required List<WorkoutSummary> workouts,
  }) {
    // Check if improved vs previous week
    if (workouts.length >= 14) {
      final thisWeekScore = _calculateMovementQualityScore(workouts.take(7).toList());
      final lastWeekScore = _calculateMovementQualityScore(
        workouts.skip(7).take(7).toList(),
      );
      
      if (thisWeekScore > lastWeekScore) {
        final delta = (thisWeekScore - lastWeekScore).toStringAsFixed(1);
        return "Your form score improved by $delta points this week.";
      } else if (lastWeekScore > thisWeekScore) {
        final delta = (lastWeekScore - thisWeekScore).toStringAsFixed(1);
        return "Focus on form this week — your score dipped $delta points.";
      }
    }

    // Check streak
    if (streak >= 7) {
      return "You're on a $streak-day streak — your consistency is elite.";
    }

    // Check perfect consistency
    if (consistency == 100.0) {
      return "Perfect week — you trained every single day.";
    }

    // Check last workout recency
    if (workouts.isNotEmpty) {
      final lastWorkout = workouts.first;
      final daysSince = DateTime.now().difference(lastWorkout.createdAt).inDays;
      
      if (daysSince >= 3) {
        return "Time to get back in the gym — your last session was $daysSince days ago.";
      }
    }

    // Default
    return "Keep training consistently to unlock deeper insights.";
  }

  // ========== WORKOUT SUGGESTION ==========

  WorkoutSuggestion? _generateWorkoutSuggestion(List<WorkoutSummary> workouts) {
    if (workouts.isEmpty) {
      return const WorkoutSuggestion(
        exerciseId: 'squat',
        exerciseName: 'Squat',
        reason: 'Perfect starting exercise for beginners',
      );
    }

    // Get workouts from last 2 days
    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final recentWorkouts = workouts.where((w) => w.createdAt.isAfter(twoDaysAgo)).toList();

    // Track which muscle groups were trained
    // This is simplified - in real implementation, would query exercises table for muscle_groups
    final trainedExercises = recentWorkouts.map((w) => w.exerciseId).toSet();

    // Simple suggestion logic based on exercises
    final allExercises = ['squat', 'deadlift', 'bench_press', 'push_up', 'pull_up'];
    
    for (final exercise in allExercises) {
      if (!trainedExercises.contains(exercise)) {
        return WorkoutSuggestion(
          exerciseId: exercise,
          exerciseName: _formatExerciseName(exercise),
          reason: 'You haven\'t trained this in 2 days',
        );
      }
    }

    // If all were trained, suggest the one with lowest form score
    if (recentWorkouts.isNotEmpty) {
      final lowestScore = recentWorkouts.reduce((a, b) => 
        a.avgFormScore < b.avgFormScore ? a : b
      );
      
      return WorkoutSuggestion(
        exerciseId: lowestScore.exerciseId,
        exerciseName: lowestScore.exerciseName,
        reason: 'Most room to improve form',
      );
    }

    return null;
  }

  String _formatExerciseName(String exerciseId) {
    return exerciseId
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  return HomeNotifier();
});
