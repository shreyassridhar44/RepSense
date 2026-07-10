import '../../data/models/gamification_models.dart';
import '../../data/services/daily_challenge_service.dart';

enum AchievementsStatus { initial, loading, success, error }

/// State for achievements screen
class AchievementsState {
  final AchievementsStatus status;
  final UserGamificationStats stats;
  final List<Achievement> achievements;
  final List<LeaderboardEntry> leaderboard;
  final DailyChallenge? todaysChallenge;
  final List<DailyChallenge> challengeHistory;
  final String? errorMessage;

  const AchievementsState({
    this.status = AchievementsStatus.initial,
    this.stats = const UserGamificationStats(
      totalXp: 0,
      level: 1,
      xpThisWeek: 0,
      xpToNextLevel: 200,
      progressToNextLevel: 0.0,
      levelTitle: 'Beginner',
      totalAchievements: 0,
      currentStreak: 0,
      challengeCompletionRate: 0.0,
    ),
    this.achievements = const [],
    this.leaderboard = const [],
    this.todaysChallenge,
    this.challengeHistory = const [],
    this.errorMessage,
  });

  AchievementsState copyWith({
    AchievementsStatus? status,
    UserGamificationStats? stats,
    List<Achievement>? achievements,
    List<LeaderboardEntry>? leaderboard,
    DailyChallenge? todaysChallenge,
    List<DailyChallenge>? challengeHistory,
    String? errorMessage,
  }) {
    return AchievementsState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      achievements: achievements ?? this.achievements,
      leaderboard: leaderboard ?? this.leaderboard,
      todaysChallenge: todaysChallenge ?? this.todaysChallenge,
      challengeHistory: challengeHistory ?? this.challengeHistory,
      errorMessage: errorMessage,
    );
  }

  // Helper getters
  bool get isLoading => status == AchievementsStatus.loading;
  bool get hasError => status == AchievementsStatus.error;
  bool get isSuccess => status == AchievementsStatus.success;

  int get earnedBadgesCount => achievements.length;
  int get totalBadgesCount => 13; // Total number of available badges

  LeaderboardEntry? get currentUserEntry {
    return leaderboard.firstWhere(
      (entry) => entry.isCurrentUser,
      orElse: () => LeaderboardEntry(
        userId: '',
        displayName: '',
        xpThisWeek: stats.xpThisWeek,
        rank: 0,
        isCurrentUser: true,
      ),
    );
  }

  int get userRank => currentUserEntry?.rank ?? 0;

  bool get hasTodaysChallenge => todaysChallenge != null;
  bool get isChallengeCompleted => todaysChallenge?.isCompleted ?? false;

  int get completedChallengesCount {
    return challengeHistory.where((c) => c.isCompleted).length;
  }
}
