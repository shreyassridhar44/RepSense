import 'package:equatable/equatable.dart';

/// Top-level summary computed from all workout history
class ProgressSnapshot extends Equatable {
  final int totalWorkouts;
  final int totalReps;
  final double totalCalories;
  final Duration totalDuration;
  final double overallAvgFormScore;
  final int currentStreakDays;
  final int longestStreakDays;
  final int totalActiveDays;
  final double weeklyConsistencyPct;
  final double monthlyConsistencyPct;
  final Map<String, int> repsByMuscleGroup;
  final Map<String, double> scoresByMuscleGroup;

  const ProgressSnapshot({
    required this.totalWorkouts,
    required this.totalReps,
    required this.totalCalories,
    required this.totalDuration,
    required this.overallAvgFormScore,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.totalActiveDays,
    required this.weeklyConsistencyPct,
    required this.monthlyConsistencyPct,
    required this.repsByMuscleGroup,
    required this.scoresByMuscleGroup,
  });

  ProgressSnapshot copyWith({
    int? totalWorkouts,
    int? totalReps,
    double? totalCalories,
    Duration? totalDuration,
    double? overallAvgFormScore,
    int? currentStreakDays,
    int? longestStreakDays,
    int? totalActiveDays,
    double? weeklyConsistencyPct,
    double? monthlyConsistencyPct,
    Map<String, int>? repsByMuscleGroup,
    Map<String, double>? scoresByMuscleGroup,
  }) {
    return ProgressSnapshot(
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalReps: totalReps ?? this.totalReps,
      totalCalories: totalCalories ?? this.totalCalories,
      totalDuration: totalDuration ?? this.totalDuration,
      overallAvgFormScore: overallAvgFormScore ?? this.overallAvgFormScore,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      longestStreakDays: longestStreakDays ?? this.longestStreakDays,
      totalActiveDays: totalActiveDays ?? this.totalActiveDays,
      weeklyConsistencyPct: weeklyConsistencyPct ?? this.weeklyConsistencyPct,
      monthlyConsistencyPct: monthlyConsistencyPct ?? this.monthlyConsistencyPct,
      repsByMuscleGroup: repsByMuscleGroup ?? this.repsByMuscleGroup,
      scoresByMuscleGroup: scoresByMuscleGroup ?? this.scoresByMuscleGroup,
    );
  }

  @override
  List<Object?> get props => [
        totalWorkouts,
        totalReps,
        totalCalories,
        totalDuration,
        overallAvgFormScore,
        currentStreakDays,
        longestStreakDays,
        totalActiveDays,
        weeklyConsistencyPct,
        monthlyConsistencyPct,
        repsByMuscleGroup,
        scoresByMuscleGroup,
      ];
}

/// Form score trend data point
class FormScoreTrend extends Equatable {
  final DateTime date;
  final double avgScore;
  final int workoutCount;

  const FormScoreTrend({
    required this.date,
    required this.avgScore,
    required this.workoutCount,
  });

  @override
  List<Object?> get props => [date, avgScore, workoutCount];
}

/// Calorie burn trend data point
class CalorieTrend extends Equatable {
  final DateTime date;
  final double calories;
  final int workoutCount;

  const CalorieTrend({
    required this.date,
    required this.calories,
    required this.workoutCount,
  });

  @override
  List<Object?> get props => [date, calories, workoutCount];
}

/// Rep volume trend data point
class RepVolumeTrend extends Equatable {
  final DateTime date;
  final int totalReps;
  final int workoutCount;

  const RepVolumeTrend({
    required this.date,
    required this.totalReps,
    required this.workoutCount,
  });

  @override
  List<Object?> get props => [date, totalReps, workoutCount];
}

/// Personal record entry
class PersonalRecord extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final double score;
  final DateTime achievedAt;
  final int reps;

  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.score,
    required this.achievedAt,
    required this.reps,
  });

  @override
  List<Object?> get props => [exerciseId, exerciseName, score, achievedAt, reps];
}

/// Consistency heatmap day
class ConsistencyDay extends Equatable {
  final DateTime date;
  final int workoutCount;

  const ConsistencyDay({
    required this.date,
    required this.workoutCount,
  });

  bool get isActive => workoutCount > 0;
  
  int get intensity {
    if (workoutCount == 0) return 0;
    if (workoutCount == 1) return 1;
    if (workoutCount == 2) return 2;
    return 3; // 3+ workouts
  }

  @override
  List<Object?> get props => [date, workoutCount];
}

/// Muscle balance radar point
class MuscleBalancePoint extends Equatable {
  final String muscleGroup;
  final double normalizedScore; // 0-100

  const MuscleBalancePoint({
    required this.muscleGroup,
    required this.normalizedScore,
  });

  @override
  List<Object?> get props => [muscleGroup, normalizedScore];
}

/// AI-generated progress prediction
class AiProgressPrediction extends Equatable {
  final String insight;
  final String recommendation;
  final double confidenceScore;

  const AiProgressPrediction({
    required this.insight,
    required this.recommendation,
    required this.confidenceScore,
  });

  @override
  List<Object?> get props => [insight, recommendation, confidenceScore];
}

/// Workout with exercise details (for repository queries)
class WorkoutWithExercise extends Equatable {
  final String id;
  final String userId;
  final String exerciseId;
  final String exerciseName;
  final String muscleGroup;
  final int totalReps;
  final int correctReps;
  final int incorrectReps;
  final double avgFormScore;
  final int durationSeconds;
  final double calories;
  final DateTime createdAt;

  const WorkoutWithExercise({
    required this.id,
    required this.userId,
    required this.exerciseId,
    required this.exerciseName,
    required this.muscleGroup,
    required this.totalReps,
    required this.correctReps,
    required this.incorrectReps,
    required this.avgFormScore,
    required this.durationSeconds,
    required this.calories,
    required this.createdAt,
  });

  factory WorkoutWithExercise.fromJson(Map<String, dynamic> json) {
    final exercise = json['exercises'] as Map<String, dynamic>?;
    
    return WorkoutWithExercise(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      exerciseId: json['exercise_id'] as String? ?? '',
      exerciseName: exercise?['name'] as String? ?? 'Unknown',
      muscleGroup: exercise?['muscle_group'] as String? ?? 'Other',
      totalReps: json['total_reps'] as int? ?? 0,
      correctReps: json['correct_reps'] as int? ?? 0,
      incorrectReps: json['incorrect_reps'] as int? ?? 0,
      avgFormScore: (json['avg_form_score'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        exerciseId,
        exerciseName,
        muscleGroup,
        totalReps,
        correctReps,
        incorrectReps,
        avgFormScore,
        durationSeconds,
        calories,
        createdAt,
      ];
}

/// Trend period filter
enum TrendPeriod {
  week,
  month,
  threeMonths,
  year;

  int get days {
    switch (this) {
      case TrendPeriod.week:
        return 7;
      case TrendPeriod.month:
        return 30;
      case TrendPeriod.threeMonths:
        return 90;
      case TrendPeriod.year:
        return 365;
    }
  }

  String get label {
    switch (this) {
      case TrendPeriod.week:
        return '7D';
      case TrendPeriod.month:
        return '30D';
      case TrendPeriod.threeMonths:
        return '3M';
      case TrendPeriod.year:
        return '1Y';
    }
  }
}
