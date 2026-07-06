import 'package:equatable/equatable.dart';
import '../../../data/models/progress_models.dart';

/// State for the Progress BLoC
sealed class ProgressState extends Equatable {
  const ProgressState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
class ProgressInitial extends ProgressState {
  const ProgressInitial();
}

/// Loading state while fetching progress data
class ProgressLoading extends ProgressState {
  const ProgressLoading();
}

/// Successfully loaded progress data
class ProgressLoaded extends ProgressState {
  final ProgressSnapshot snapshot;
  final List<FormScoreTrend> formTrend;
  final List<CalorieTrend> calorieTrend;
  final List<RepVolumeTrend> repVolumeTrend;
  final List<PersonalRecord> personalRecords;
  final List<ConsistencyDay> consistencyHeatmap;
  final List<MuscleBalancePoint> muscleBalance;
  final AiProgressPrediction? aiPrediction;
  final TrendPeriod selectedPeriod;

  const ProgressLoaded({
    required this.snapshot,
    required this.formTrend,
    required this.calorieTrend,
    required this.repVolumeTrend,
    required this.personalRecords,
    required this.consistencyHeatmap,
    required this.muscleBalance,
    this.aiPrediction,
    this.selectedPeriod = TrendPeriod.month,
  });

  ProgressLoaded copyWith({
    ProgressSnapshot? snapshot,
    List<FormScoreTrend>? formTrend,
    List<CalorieTrend>? calorieTrend,
    List<RepVolumeTrend>? repVolumeTrend,
    List<PersonalRecord>? personalRecords,
    List<ConsistencyDay>? consistencyHeatmap,
    List<MuscleBalancePoint>? muscleBalance,
    AiProgressPrediction? aiPrediction,
    TrendPeriod? selectedPeriod,
  }) {
    return ProgressLoaded(
      snapshot: snapshot ?? this.snapshot,
      formTrend: formTrend ?? this.formTrend,
      calorieTrend: calorieTrend ?? this.calorieTrend,
      repVolumeTrend: repVolumeTrend ?? this.repVolumeTrend,
      personalRecords: personalRecords ?? this.personalRecords,
      consistencyHeatmap: consistencyHeatmap ?? this.consistencyHeatmap,
      muscleBalance: muscleBalance ?? this.muscleBalance,
      aiPrediction: aiPrediction ?? this.aiPrediction,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
    );
  }

  @override
  List<Object?> get props => [
        snapshot,
        formTrend,
        calorieTrend,
        repVolumeTrend,
        personalRecords,
        consistencyHeatmap,
        muscleBalance,
        aiPrediction,
        selectedPeriod,
      ];
}

/// Error state when progress data fetch fails
class ProgressError extends ProgressState {
  final String message;

  const ProgressError(this.message);

  @override
  List<Object?> get props => [message];
}
