import 'package:equatable/equatable.dart';
import '../../data/models/inference_models.dart';

enum SummaryStatus {
  analyzing,
  savingToCloud,
  complete,
  inferenceError,
  saveError,
}

class SummaryState extends Equatable {
  final SummaryStatus status;

  // Always available immediately (from camera output)
  final String exerciseId;
  final String exerciseName;
  final int totalReps;
  final int correctReps;
  final int incorrectReps;
  final List<bool> repQuality;
  final int durationSeconds;
  final double estimatedCalories;
  final DateTime sessionStartTime;
  final List<Map<String, double>> angleSequence;

  // Available after inference completes
  final InferenceResult? inferenceResult;
  final String? workoutSummaryText;
  final String? savedWorkoutId;
  final List<String> newlyUnlockedAchievements;

  // Error handling
  final String? inferenceErrorMessage;
  final bool inferenceFailedButSaved;
  final String? saveErrorMessage;
  final bool isSaved;

  const SummaryState({
    this.status = SummaryStatus.analyzing,
    this.exerciseId = '',
    this.exerciseName = '',
    this.totalReps = 0,
    this.correctReps = 0,
    this.incorrectReps = 0,
    this.repQuality = const [],
    this.durationSeconds = 0,
    this.estimatedCalories = 0.0,
    required this.sessionStartTime,
    this.angleSequence = const [],
    this.inferenceResult,
    this.workoutSummaryText,
    this.savedWorkoutId,
    this.newlyUnlockedAchievements = const [],
    this.inferenceErrorMessage,
    this.inferenceFailedButSaved = false,
    this.saveErrorMessage,
    this.isSaved = false,
  });

  // Derived getters
  double get displayScore => inferenceResult?.avgScore ?? _basicScore;
  
  double get _basicScore {
    if (totalReps == 0) return 0.0;
    return (correctReps / totalReps * 100);
  }

  SummaryState copyWith({
    SummaryStatus? status,
    String? exerciseId,
    String? exerciseName,
    int? totalReps,
    int? correctReps,
    int? incorrectReps,
    List<bool>? repQuality,
    int? durationSeconds,
    double? estimatedCalories,
    DateTime? sessionStartTime,
    List<Map<String, double>>? angleSequence,
    InferenceResult? inferenceResult,
    String? workoutSummaryText,
    String? savedWorkoutId,
    List<String>? newlyUnlockedAchievements,
    String? inferenceErrorMessage,
    bool? inferenceFailedButSaved,
    String? saveErrorMessage,
    bool? isSaved,
  }) {
    return SummaryState(
      status: status ?? this.status,
      exerciseId: exerciseId ?? this.exerciseId,
      exerciseName: exerciseName ?? this.exerciseName,
      totalReps: totalReps ?? this.totalReps,
      correctReps: correctReps ?? this.correctReps,
      incorrectReps: incorrectReps ?? this.incorrectReps,
      repQuality: repQuality ?? this.repQuality,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      estimatedCalories: estimatedCalories ?? this.estimatedCalories,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      angleSequence: angleSequence ?? this.angleSequence,
      inferenceResult: inferenceResult ?? this.inferenceResult,
      workoutSummaryText: workoutSummaryText ?? this.workoutSummaryText,
      savedWorkoutId: savedWorkoutId ?? this.savedWorkoutId,
      newlyUnlockedAchievements: newlyUnlockedAchievements ?? this.newlyUnlockedAchievements,
      inferenceErrorMessage: inferenceErrorMessage,
      inferenceFailedButSaved: inferenceFailedButSaved ?? this.inferenceFailedButSaved,
      saveErrorMessage: saveErrorMessage,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  @override
  List<Object?> get props => [
        status,
        exerciseId,
        exerciseName,
        totalReps,
        correctReps,
        incorrectReps,
        repQuality,
        durationSeconds,
        estimatedCalories,
        sessionStartTime,
        angleSequence,
        inferenceResult,
        workoutSummaryText,
        savedWorkoutId,
        newlyUnlockedAchievements,
        inferenceErrorMessage,
        inferenceFailedButSaved,
        saveErrorMessage,
        isSaved,
      ];
}
