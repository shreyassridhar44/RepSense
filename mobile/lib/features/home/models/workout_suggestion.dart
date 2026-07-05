import 'package:equatable/equatable.dart';

class WorkoutSuggestion extends Equatable {
  final String exerciseId;
  final String exerciseName;
  final String reason;

  const WorkoutSuggestion({
    required this.exerciseId,
    required this.exerciseName,
    required this.reason,
  });

  WorkoutSuggestion copyWith({
    String? exerciseId,
    String? exerciseName,
    String? reason,
  }) {
    return WorkoutSuggestion(
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      reason: reason ?? this.reason,
    );
  }

  @override
  List<Object?> get props => [exerciseId, exerciseName, reason];
}
