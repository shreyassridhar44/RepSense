import '../../core/utils/app_logger.dart';
import '../models/gamification_models.dart';
import '../services/daily_challenge_service.dart';
import '../services/xp_service.dart';
import '../supabase/supabase_service.dart';

/// Repository for achievements and gamification data
class AchievementsRepository {
  final SupabaseService _supabase;
  final DailyChallengeService _challengeService;

  AchievementsRepository({
    SupabaseService? supabase,
    DailyChallengeService? challengeService,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _challengeService = challengeService ?? DailyChallengeService();

  /// Get user's achievements
  Future<List<Achievement>> getUserAchievements(String userId) async {
    try {
      final result = await _supabase.client
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('earned_at', ascending: false);

      return (result as List).map((json) => Achievement.fromJson(json)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to get achievements', e, stack);
      return [];
    }
  }

  /// Get user gamification stats
  Future<UserGamificationStats> getUserStats(String userId) async {
    try {
      // Get profile
      final profile = await _supabase.getProfile(userId);
      if (profile == null) {
        throw Exception('Profile not found');
      }

      final totalXp = profile['xp_total'] as int? ?? 0;
      final level = profile['level'] as int? ?? 1;
      final xpThisWeek = profile['xp_this_week'] as int? ?? 0;

      // Get achievements count
      final achievements = await getUserAchievements(userId);

      // Get current streak
      final workouts = await _supabase.client
          .from('workouts')
          .select('created_at')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final currentStreak = _calculateStreak(workouts as List);

      // Get challenge completion rate
      final completionRate = await _challengeService.getCompletionRate(userId);

      return UserGamificationStats(
        totalXp: totalXp,
        level: level,
        xpThisWeek: xpThisWeek,
        xpToNextLevel: LevelSystem.xpToNextLevel(totalXp),
        progressToNextLevel: LevelSystem.progressToNextLevel(totalXp),
        levelTitle: LevelSystem.levelTitle(level),
        totalAchievements: achievements.length,
        currentStreak: currentStreak,
        challengeCompletionRate: completionRate,
      );
    } catch (e, stack) {
      AppLogger.error('Failed to get user stats', e, stack);
      return const UserGamificationStats(
        totalXp: 0,
        level: 1,
        xpThisWeek: 0,
        xpToNextLevel: 200,
        progressToNextLevel: 0.0,
        levelTitle: 'Beginner',
        totalAchievements: 0,
        currentStreak: 0,
        challengeCompletionRate: 0.0,
      );
    }
  }

  /// Get weekly leaderboard
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({
    required String currentUserId,
    int limit = 50,
  }) async {
    try {
      final weekStart = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1),
      );

      final result = await _supabase.client
          .from('leaderboard_weekly')
          .select()
          .eq('week_start', weekStart.toIso8601String().split('T')[0])
          .order('xp_this_week', ascending: false)
          .limit(limit);

      final entries = (result as List).asMap().entries.map((entry) {
        final json = entry.value as Map<String, dynamic>;
        json['rank'] = entry.key + 1;
        return LeaderboardEntry.fromJson(json, currentUserId);
      }).toList();

      return entries;
    } catch (e, stack) {
      AppLogger.error('Failed to get leaderboard', e, stack);
      return [];
    }
  }

  /// Get today's daily challenge
  Future<DailyChallenge?> getTodaysChallenge(String userId) async {
    return await _challengeService.getTodaysChallenge(userId);
  }

  /// Get challenge history
  Future<List<DailyChallenge>> getChallengeHistory(String userId, {int limit = 30}) async {
    return await _challengeService.getChallengeHistory(userId, limit: limit);
  }

  /// Calculate current streak
  int _calculateStreak(List<dynamic> workouts) {
    if (workouts.isEmpty) return 0;

    final dates = workouts
        .map((w) => DateTime.parse(w['created_at'] as String))
        .map((dt) => DateTime(dt.year, dt.month, dt.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    int streak = 1;
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    // Check if most recent workout is today or yesterday
    if (dates[0] != todayDate && dates[0] != todayDate.subtract(const Duration(days: 1))) {
      return 0;
    }

    for (int i = 1; i < dates.length; i++) {
      final diff = dates[i - 1].difference(dates[i]).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
