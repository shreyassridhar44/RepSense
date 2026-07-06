import 'package:equatable/equatable.dart';
import '../../../data/models/progress_models.dart';

/// Events for the Progress BLoC
sealed class ProgressEvent extends Equatable {
  const ProgressEvent();

  @override
  List<Object?> get props => [];
}

/// Load all progress data for the current user
class LoadProgress extends ProgressEvent {
  const LoadProgress();
}

/// Refresh progress data (clears cache)
class RefreshProgress extends ProgressEvent {
  const RefreshProgress();
}

/// Change the trend period filter
class ChangeTrendPeriod extends ProgressEvent {
  final TrendPeriod period;

  const ChangeTrendPeriod(this.period);

  @override
  List<Object?> get props => [period];
}

/// Request AI prediction
class RequestAiPrediction extends ProgressEvent {
  const RequestAiPrediction();
}
