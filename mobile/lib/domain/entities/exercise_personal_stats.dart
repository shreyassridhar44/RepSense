import 'package:equatable/equatable.dart';

class ExercisePersonalStats extends Equatable {
  final int totalSessions;
  final int totalReps;
  final double avgFormScore;
  final double bestFormScore;
  final int bestRepsInSession;
  final DateTime? lastPerformed;
  final double improvementTrend;

  const ExercisePersonalStats({
    this.totalSessions = 0,
    this.totalReps = 0,
    this.avgFormScore = 0.0,
    this.bestFormScore = 0.0,
    this.bestRepsInSession = 0,
    this.lastPerformed,
    this.improvementTrend = 0.0,
  });

  bool get hasData => totalSessions > 0;
  bool get hasEnoughDataForTrend => totalSessions >= 6;

  String get trendDescription {
    if (!hasEnoughDataForTrend) return 'not_enough';
    if (improvementTrend > 2) return 'improving';
    if (improvementTrend < -2) return 'declining';
    return 'stable';
  }

  @override
  List<Object?> get props => [
        totalSessions,
        totalReps,
        avgFormScore,
        bestFormScore,
        bestRepsInSession,
        lastPerformed,
        improvementTrend,
      ];
}
