import 'package:equatable/equatable.dart';

class PersonalBest extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final int bestReps;
  final double bestFormScore;
  final DateTime achievedAt;

  const PersonalBest({
    required this.exerciseId,
    required this.exerciseName,
    required this.bestReps,
    required this.bestFormScore,
    required this.achievedAt,
  });

  PersonalBest copyWith({
    String? exerciseId,
    String? exerciseName,
    int? bestReps,
    double? bestFormScore,
    DateTime? achievedAt,
  }) {
    return PersonalBest(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      bestReps: bestReps ?? this.bestReps,
      bestFormScore: bestFormScore ?? this.bestFormScore,
      achievedAt: achievedAt ?? this.achievedAt,
    );
  }

  @override
  List<Object?> get props => [
        exerciseId,
        exerciseName,
        bestReps,
        bestFormScore,
        achievedAt,
      ];
}
