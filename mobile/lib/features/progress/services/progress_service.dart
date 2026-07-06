import 'package:collection/collection.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/models/progress_models.dart';
import '../../../data/repositories/progress_repository.dart';

/// Core business logic for computing all progress analytics
/// Processes raw workout data into meaningful insights
class ProgressService {
  final ProgressRepository _repository;

  ProgressService({ProgressRepository? repository})
      : _repository = repository ?? ProgressRepository();

  /// Compute complete progress snapshot from all user workouts
  Future<ProgressSnapshot> computeSnapshot(String userId) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);

    if (workouts.isEmpty) {
      return _emptySnapshot();
    }

    final totalWorkouts = workouts.length;
    final totalReps = workouts.fold<int>(0, (sum, w) => sum + w.totalReps);
    final totalCalories = workouts.fold<double>(0, (sum, w) => sum + w.calories);
    final totalDuration = Duration(
      seconds: workouts.fold<int>(0, (sum, w) => sum + w.durationSeconds),
    );

    // Calculate average form score
    final overallAvgFormScore = workouts
            .map((w) => w.avgFormScore)
            .average *
        100;

    // Compute streaks
    final activeDays = _getActiveDays(workouts);
    final currentStreak = _computeCurrentStreak(activeDays);
    final longestStreak = _computeLongestStreak(activeDays);
    final totalActiveDays = activeDays.length;

    // Consistency percentages
    final now = DateTime.now();
    final weeklyConsistency = _computeConsistency(activeDays, now.subtract(const Duration(days: 7)), now);
    final monthlyConsistency = _computeConsistency(activeDays, now.subtract(const Duration(days: 30)), now);

    // Group by muscle
    final repsByMuscle = <String, int>{};
    final scoresByMuscle = <String, List<double>>{};

    for (final workout in workouts) {
      repsByMuscle[workout.muscleGroup] =
          (repsByMuscle[workout.muscleGroup] ?? 0) + workout.totalReps;
      scoresByMuscle.putIfAbsent(workout.muscleGroup, () => []);
      scoresByMuscle[workout.muscleGroup]!.add(workout.avgFormScore);
    }

    final scoresByMuscleAvg = scoresByMuscle.map(
      (muscle, scores) => MapEntry(muscle, scores.average * 100),
    );

    AppLogger.info('✅ Computed progress snapshot: $totalWorkouts workouts, $totalReps reps');

    return ProgressSnapshot(
      totalWorkouts: totalWorkouts,
      totalReps: totalReps,
      totalCalories: totalCalories,
      totalDuration: totalDuration,
      overallAvgFormScore: overallAvgFormScore,
      currentStreakDays: currentStreak,
      longestStreakDays: longestStreak,
      totalActiveDays: totalActiveDays,
      weeklyConsistencyPct: weeklyConsistency,
      monthlyConsistencyPct: monthlyConsistency,
      repsByMuscleGroup: repsByMuscle,
      scoresByMuscleGroup: scoresByMuscleAvg,
    );
  }

  /// Compute form score trend for a given period
  Future<List<FormScoreTrend>> getFormScoreTrend(
    String userId,
    TrendPeriod period,
  ) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);
    final cutoffDate = DateTime.now().subtract(Duration(days: period.days));
    final filtered = workouts.where((w) => w.createdAt.isAfter(cutoffDate)).toList();

    // Group by date
    final grouped = groupBy<WorkoutWithExercise, String>(
      filtered,
      (w) => _dateKey(w.createdAt),
    );

    final trends = grouped.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final dayWorkouts = entry.value;
      final avgScore = dayWorkouts.map((w) => w.avgFormScore).average * 100;

      return FormScoreTrend(
        date: date,
        avgScore: avgScore,
        workoutCount: dayWorkouts.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  /// Compute calorie burn trend for a given period
  Future<List<CalorieTrend>> getCalorieTrend(
    String userId,
    TrendPeriod period,
  ) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);
    final cutoffDate = DateTime.now().subtract(Duration(days: period.days));
    final filtered = workouts.where((w) => w.createdAt.isAfter(cutoffDate)).toList();

    final grouped = groupBy<WorkoutWithExercise, String>(
      filtered,
      (w) => _dateKey(w.createdAt),
    );

    final trends = grouped.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final dayWorkouts = entry.value;
      final totalCal = dayWorkouts.fold<double>(0, (sum, w) => sum + w.calories);

      return CalorieTrend(
        date: date,
        calories: totalCal,
        workoutCount: dayWorkouts.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  /// Compute rep volume trend for a given period
  Future<List<RepVolumeTrend>> getRepVolumeTrend(
    String userId,
    TrendPeriod period,
  ) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);
    final cutoffDate = DateTime.now().subtract(Duration(days: period.days));
    final filtered = workouts.where((w) => w.createdAt.isAfter(cutoffDate)).toList();

    final grouped = groupBy<WorkoutWithExercise, String>(
      filtered,
      (w) => _dateKey(w.createdAt),
    );

    final trends = grouped.entries.map((entry) {
      final date = DateTime.parse(entry.key);
      final dayWorkouts = entry.value;
      final totalReps = dayWorkouts.fold<int>(0, (sum, w) => sum + w.totalReps);

      return RepVolumeTrend(
        date: date,
        totalReps: totalReps,
        workoutCount: dayWorkouts.length,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return trends;
  }

  /// Get personal records (best form scores per exercise)
  Future<List<PersonalRecord>> getPersonalRecords(String userId) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);

    final byExercise = groupBy<WorkoutWithExercise, String>(
      workouts,
      (w) => w.exerciseId,
    );

    final records = <PersonalRecord>[];

    for (final entry in byExercise.entries) {
      final exerciseWorkouts = entry.value;
      final best = exerciseWorkouts.reduce(
        (a, b) => a.avgFormScore > b.avgFormScore ? a : b,
      );

      records.add(PersonalRecord(
        exerciseId: best.exerciseId,
        exerciseName: best.exerciseName,
        score: best.avgFormScore * 100,
        achievedAt: best.createdAt,
        reps: best.totalReps,
      ));
    }

    records.sort((a, b) => b.score.compareTo(a.score));
    return records;
  }

  /// Get consistency heatmap for last 90 days
  Future<List<ConsistencyDay>> getConsistencyHeatmap(String userId) async {
    final workouts = await _repository.getAllWorkoutsWithExercise(userId);
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 90));

    final grouped = groupBy<WorkoutWithExercise, String>(
      workouts.where((w) => w.createdAt.isAfter(startDate)),
      (w) => _dateKey(w.createdAt),
    );

    final heatmap = <ConsistencyDay>[];
    for (int i = 0; i <= 90; i++) {
      final date = startDate.add(Duration(days: i));
      final key = _dateKey(date);
      final count = grouped[key]?.length ?? 0;

      heatmap.add(ConsistencyDay(date: date, workoutCount: count));
    }

    return heatmap;
  }

  /// Get muscle balance radar data
  Future<List<MuscleBalancePoint>> getMuscleBalance(String userId) async {
    final snapshot = await computeSnapshot(userId);

    if (snapshot.repsByMuscleGroup.isEmpty) {
      return [];
    }

    // Normalize rep counts to 0-100 scale
    final maxReps = snapshot.repsByMuscleGroup.values.reduce((a, b) => a > b ? a : b);

    return snapshot.repsByMuscleGroup.entries.map((entry) {
      final normalized = (entry.value / maxReps) * 100;
      return MuscleBalancePoint(
        muscleGroup: entry.key,
        normalizedScore: normalized,
      );
    }).toList();
  }

  /// Generate AI-powered prediction (placeholder - integrate with LLM service)
  Future<AiProgressPrediction> getAiPrediction(String userId) async {
    final snapshot = await computeSnapshot(userId);

    // Simple rule-based prediction (can be enhanced with actual AI)
    String insight;
    String recommendation;
    double confidence = 0.75;

    if (snapshot.currentStreakDays >= 7) {
      insight = 'Your consistency is excellent! Keep up the momentum.';
      recommendation = 'Focus on progressive overload to maximize gains.';
      confidence = 0.85;
    } else if (snapshot.weeklyConsistencyPct < 50) {
      insight = 'Your workout frequency has decreased recently.';
      recommendation = 'Try scheduling workouts at the same time each day.';
      confidence = 0.70;
    } else {
      insight = 'You\'re making steady progress across all muscle groups.';
      recommendation = 'Consider increasing intensity for faster results.';
      confidence = 0.75;
    }

    return AiProgressPrediction(
      insight: insight,
      recommendation: recommendation,
      confidenceScore: confidence,
    );
  }

  // ========== Private Helpers ==========

  ProgressSnapshot _emptySnapshot() {
    return const ProgressSnapshot(
      totalWorkouts: 0,
      totalReps: 0,
      totalCalories: 0,
      totalDuration: Duration.zero,
      overallAvgFormScore: 0,
      currentStreakDays: 0,
      longestStreakDays: 0,
      totalActiveDays: 0,
      weeklyConsistencyPct: 0,
      monthlyConsistencyPct: 0,
      repsByMuscleGroup: {},
      scoresByMuscleGroup: {},
    );
  }

  Set<String> _getActiveDays(List<WorkoutWithExercise> workouts) {
    return workouts.map((w) => _dateKey(w.createdAt)).toSet();
  }

  String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  int _computeCurrentStreak(Set<String> activeDays) {
    int streak = 0;
    final now = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final date = now.subtract(Duration(days: i));
      final key = _dateKey(date);

      if (activeDays.contains(key)) {
        streak++;
      } else if (i > 0) {
        // Allow one "grace day" for today
        break;
      }
    }

    return streak;
  }

  int _computeLongestStreak(Set<String> activeDays) {
    if (activeDays.isEmpty) return 0;

    final sorted = activeDays.toList()..sort();
    int longest = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);

      if (curr.difference(prev).inDays == 1) {
        current++;
        longest = current > longest ? current : longest;
      } else {
        current = 1;
      }
    }

    return longest;
  }

  double _computeConsistency(Set<String> activeDays, DateTime start, DateTime end) {
    final totalDays = end.difference(start).inDays + 1;
    int activeDaysInRange = 0;

    for (int i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      final key = _dateKey(date);
      if (activeDays.contains(key)) {
        activeDaysInRange++;
      }
    }

    return totalDays > 0 ? (activeDaysInRange / totalDays) * 100 : 0;
  }
}
