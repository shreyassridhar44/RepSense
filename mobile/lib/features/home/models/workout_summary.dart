import 'package:equatable/equatable.dart';

class WorkoutSummary extends Equatable {
  final String id;
  final String exerciseId;
  final String exerciseName;
  final int totalReps;
  final int correctReps;
  final double avgFormScore;
  final int durationSeconds;
  final double? calories;
  final DateTime createdAt;

  const WorkoutSummary({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
    required this.totalReps,
    required this.correctReps,
    required this.avgFormScore,
    required this.durationSeconds,
    this.calories,
    required this.createdAt,
  });

  factory WorkoutSummary.fromJson(Map<String, dynamic> json) {
    return WorkoutSummary(
      id: json['id'] as String,
      exerciseId: json['exercise_id'] as String,
      exerciseName: json['exercise_name'] as String? ?? 'Unknown Exercise',
      totalReps: json['total_reps'] as int? ?? 0,
      correctReps: json['correct_reps'] as int? ?? 0,
      avgFormScore: (json['avg_form_score'] as num?)?.toDouble() ?? 0.0,
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      calories: (json['calories'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  WorkoutSummary copyWith({
    String? id,
    String? exerciseId,
    String? exerciseName,
    int? totalReps,
    int? correctReps,
    double? avgFormScore,
    int? durationSeconds,
    double? calories,
    DateTime? createdAt,
  }) {
    return WorkoutSummary(
      id: id ?? this.id,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      totalReps: totalReps ?? this.totalReps,
      correctReps: correctReps ?? this.correctReps,
      avgFormScore: avgFormScore ?? this.avgFormScore,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      calories: calories ?? this.calories,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        exerciseId,
        exerciseName,
        totalReps,
        correctReps,
        avgFormScore,
        durationSeconds,
        calories,
        createdAt,
      ];
}
