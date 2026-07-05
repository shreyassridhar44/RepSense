import 'package:equatable/equatable.dart';
import 'models/achievement.dart';
import 'models/personal_best.dart';
import 'models/workout_suggestion.dart';
import 'models/workout_summary.dart';

enum HomeStatus { loading, loaded, error }

class HomeState extends Equatable {
  final HomeStatus status;
  final String? errorMessage;
  final bool isRefreshing;
  
  // User info
  final String displayName;
  
  // Stats
  final int currentStreakDays;
  final double weeklyConsistencyPct;
  final double totalCaloriesToday;
  final double movementQualityScore;
  final double stabilityScore;
  final double symmetryScore;
  
  // Data
  final List<WorkoutSummary> recentWorkouts;
  final List<Achievement> recentAchievements;
  final Map<String, PersonalBest> personalBests;
  
  // Insights
  final String weeklyInsight;
  final WorkoutSuggestion? todayWorkoutSuggestion;
  
  // Metadata
  final DateTime? lastUpdated;

  const HomeState({
    this.status = HomeStatus.loading,
    this.errorMessage,
    this.isRefreshing = false,
    this.displayName = '',
    this.currentStreakDays = 0,
    this.weeklyConsistencyPct = 0.0,
    this.totalCaloriesToday = 0.0,
    this.movementQualityScore = 0.0,
    this.stabilityScore = 0.0,
    this.symmetryScore = 0.0,
    this.recentWorkouts = const [],
    this.recentAchievements = const [],
    this.personalBests = const {},
    this.weeklyInsight = '',
    this.todayWorkoutSuggestion,
    this.lastUpdated,
  });

  HomeState copyWith({
    HomeStatus? status,
    String? errorMessage,
    bool? isRefreshing,
    String? displayName,
    int? currentStreakDays,
    double? weeklyConsistencyPct,
    double? totalCaloriesToday,
    double? movementQualityScore,
    double? stabilityScore,
    double? symmetryScore,
    List<WorkoutSummary>? recentWorkouts,
    List<Achievement>? recentAchievements,
    Map<String, PersonalBest>? personalBests,
    String? weeklyInsight,
    WorkoutSuggestion? todayWorkoutSuggestion,
    DateTime? lastUpdated,
  }) {
    return HomeState(
      status: status ?? this.status,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      displayName: displayName ?? this.displayName,
      currentStreakDays: currentStreakDays ?? this.currentStreakDays,
      weeklyConsistencyPct: weeklyConsistencyPct ?? this.weeklyConsistencyPct,
      totalCaloriesToday: totalCaloriesToday ?? this.totalCaloriesToday,
      movementQualityScore: movementQualityScore ?? this.movementQualityScore,
      stabilityScore: stabilityScore ?? this.stabilityScore,
      symmetryScore: symmetryScore ?? this.symmetryScore,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      recentAchievements: recentAchievements ?? this.recentAchievements,
      personalBests: personalBests ?? this.personalBests,
      weeklyInsight: weeklyInsight ?? this.weeklyInsight,
      todayWorkoutSuggestion: todayWorkoutSuggestion ?? this.todayWorkoutSuggestion,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        isRefreshing,
        displayName,
        currentStreakDays,
        weeklyConsistencyPct,
        totalCaloriesToday,
        movementQualityScore,
        stabilityScore,
        symmetryScore,
        recentWorkouts,
        recentAchievements,
        personalBests,
        weeklyInsight,
        todayWorkoutSuggestion,
        lastUpdated,
      ];
}
