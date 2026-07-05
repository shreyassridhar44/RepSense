import 'package:equatable/equatable.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/exercise_personal_stats.dart';

enum ExerciseDetailStatus { loading, loaded, error }

class ExerciseDetailState extends Equatable {
  final ExerciseDetailStatus status;
  final Exercise? exercise;
  final ExercisePersonalStats? stats;
  final String? errorMessage;

  const ExerciseDetailState({
    this.status = ExerciseDetailStatus.loading,
    this.exercise,
    this.stats,
    this.errorMessage,
  });

  ExerciseDetailState copyWith({
    ExerciseDetailStatus? status,
    Exercise? exercise,
    ExercisePersonalStats? stats,
    String? errorMessage,
  }) {
    return ExerciseDetailState(
      status: status ?? this.status,
      exercise: exercise ?? this.exercise,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, exercise, stats, errorMessage];
}
