import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/models/gamification_models.dart';
import '../../data/services/daily_challenge_service.dart';
import 'achievements_state.dart';

/// Notifier for achievements screen
class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final AchievementsRepository _repository;
  final String _userId;

  AchievementsNotifier({
    required AchievementsRepository repository,
    required String userId,
  })  : _repository = repository,
        _userId = userId,
        super(const AchievementsState());

  /// Load all achievements data
  Future<void> loadData() async {
    if (state.status == AchievementsStatus.loading) return;

    try {
      state = state.copyWith(status: AchievementsStatus.loading);
      AppLogger.info('📊 Loading achievements data');

      // Load all data concurrently
      final results = await Future.wait([
        _repository.getUserStats(_userId),
        _repository.getUserAchievements(_userId),
        _repository.getWeeklyLeaderboard(currentUserId: _userId),
        _repository.getTodaysChallenge(_userId),
        _repository.getChallengeHistory(_userId, limit: 30),
      ]);

      state = state.copyWith(
        status: AchievementsStatus.success,
        stats: results[0] as UserGamificationStats?,
        achievements: results[1] as List<Achievement>?,
        leaderboard: results[2] as List<LeaderboardEntry>?,
        todaysChallenge: results[3] as DailyChallenge?,
        challengeHistory: results[4] as List<DailyChallenge>?,
      );

      AppLogger.info('✅ Achievements data loaded');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to load achievements', e, stack);
      state = state.copyWith(
        status: AchievementsStatus.error,
        errorMessage: 'Failed to load achievements',
      );
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    await loadData();
  }

  /// Refresh specific sections
  Future<void> refreshStats() async {
    try {
      final stats = await _repository.getUserStats(_userId);
      state = state.copyWith(stats: stats);
    } catch (e) {
      AppLogger.error('Failed to refresh stats', e);
    }
  }

  Future<void> refreshLeaderboard() async {
    try {
      final leaderboard = await _repository.getWeeklyLeaderboard(
        currentUserId: _userId,
      );
      state = state.copyWith(leaderboard: leaderboard);
    } catch (e) {
      AppLogger.error('Failed to refresh leaderboard', e);
    }
  }

  Future<void> refreshChallenge() async {
    try {
      final challenge = await _repository.getTodaysChallenge(_userId);
      state = state.copyWith(todaysChallenge: challenge);
    } catch (e) {
      AppLogger.error('Failed to refresh challenge', e);
    }
  }
}
