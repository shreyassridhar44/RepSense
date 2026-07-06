import '../../core/utils/app_logger.dart';
import '../../data/models/inference_models.dart';
import '../supabase/supabase_service.dart';
import 'xp_service.dart';

/// Service for checking and unlocking achievements
class AchievementService {
  final SupabaseService _supabase;
  final XpService _xpService;

  AchievementService({
    SupabaseService? supabase,
    XpService? xpService,
  })  : _supabase = supabase ?? SupabaseService.instance,
        _xpService = xpService ?? XpService();

  /// Check and unlock applicable achievements after a workout
  Future<List<String>> checkAndUnlock({
    required String userId,
    required List<Map<String, dynamic>> allWorkouts,
    required InferenceResult? inferenceResult,
  }) async {
    try {
      AppLogger.info('🏆 Checking achievements for user: $userId');

      final newlyUnlocked = <String>[];

      // First workout
      if (allWorkouts.length == 1) {
        await _unlockIfNotAlreadyEarned(userId, 'first_workout');
        newlyUnlocked.add('first_workout');
      }

      // Total reps milestones
      final totalReps = allWorkouts.fold<int>(
        0,
        (sum, w) => sum + (w['total_reps'] as int? ?? 0),
      );

      if (totalReps >= 100 && !await _hasAchievement(userId, '100_reps')) {
        await _unlockIfNotAlreadyEarned(userId, '100_reps');
        newlyUnlocked.add('100_reps');
      }

      if (totalReps >= 1000 && !await _hasAchievement(userId, '1000_reps')) {
        await _unlockIfNotAlreadyEarned(userId, '1000_reps');
        newlyUnlocked.add('1000_reps');
      }

      // Streak milestones
      final currentStreak = _calculateStreak(allWorkouts);

      if (currentStreak >= 7 && !await _hasAchievement(userId, '7_day_streak')) {
        await _unlockIfNotAlreadyEarned(userId, '7_day_streak');
        newlyUnlocked.add('7_day_streak');
      }

      if (currentStreak >= 30 && !await _hasAchievement(userId, '30_day_streak')) {
        await _unlockIfNotAlreadyEarned(userId, '30_day_streak');
        newlyUnlocked.add('30_day_streak');
      }

      // Perfect form (requires inference result)
      if (inferenceResult != null) {
        // Check if any rep has perfect score
        final hasPerfectRep = inferenceResult.reps.any((r) => r.overallScore >= 100);
        final hasNearPerfectAvg = inferenceResult.avgScore >= 98;

        if ((hasPerfectRep || hasNearPerfectAvg) &&
            !await _hasAchievement(userId, 'perfect_form')) {
          await _unlockIfNotAlreadyEarned(userId, 'perfect_form');
          newlyUnlocked.add('perfect_form');
        }

        // Balanced form
        final hasBalancedForm = inferenceResult.scoresBreakdown.symmetry >= 95 &&
            inferenceResult.scoresBreakdown.stability >= 95;

        if (hasBalancedForm && !await _hasAchievement(userId, 'balanced_form')) {
          await _unlockIfNotAlreadyEarned(userId, 'balanced_form');
          newlyUnlocked.add('balanced_form');
        }
      }

      // Consistent (2 weeks with >=85% consistency)
      if (_hasConsistentStreak(allWorkouts) &&
          !await _hasAchievement(userId, 'consistent')) {
        await _unlockIfNotAlreadyEarned(userId, 'consistent');
        newlyUnlocked.add('consistent');
      }

      // Level achievements
      final profile = await _supabase.getProfile(userId);
      final level = profile?['level'] as int? ?? 1;

      if (level >= 5 && !await _hasAchievement(userId, 'level_5')) {
        await _unlockIfNotAlreadyEarned(userId, 'level_5');
        newlyUnlocked.add('level_5');
      }

      if (level >= 10 && !await _hasAchievement(userId, 'level_10')) {
        await _unlockIfNotAlreadyEarned(userId, 'level_10');
        newlyUnlocked.add('level_10');
      }

      if (level >= 20 && !await _hasAchievement(userId, 'level_20')) {
        await _unlockIfNotAlreadyEarned(userId, 'level_20');
        newlyUnlocked.add('level_20');
      }

      // Award XP for each badge unlocked
      for (final badge in newlyUnlocked) {
        await _xpService.awardXp(
          userId: userId,
          amount: XpRewards.badgeUnlocked,
          reason: 'Badge unlocked: $badge',
        );
      }

      if (newlyUnlocked.isNotEmpty) {
        AppLogger.info('🎉 Unlocked ${newlyUnlocked.length} achievement(s): $newlyUnlocked');
      }

      return newlyUnlocked;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to check achievements', e, stack);
      return []; // Non-critical, return empty list
    }
  }

  /// Check if user already has an achievement
  Future<bool> _hasAchievement(String userId, String badgeKey) async {
    final result = await _supabase.client
        .from('achievements')
        .select('id')
        .eq('user_id', userId)
        .eq('badge_key', badgeKey)
        .maybeSingle();

    return result != null;
  }

  /// Unlock achievement if not already earned
  Future<void> _unlockIfNotAlreadyEarned(String userId, String badgeKey) async {
    try {
      await _supabase.client.from('achievements').upsert(
        {
          'user_id': userId,
          'badge_key': badgeKey,
          'earned_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id,badge_key',
      );

      AppLogger.info('✅ Unlocked achievement: $badgeKey');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to unlock achievement: $badgeKey', e, stack);
    }
  }

  /// Calculate current streak
  int _calculateStreak(List<Map<String, dynamic>> workouts) {
    if (workouts.isEmpty) return 0;

    // Sort by date descending
    final sorted = List<Map<String, dynamic>>.from(workouts)
      ..sort((a, b) {
        final dateA = DateTime.parse(a['created_at'] as String);
        final dateB = DateTime.parse(b['created_at'] as String);
        return dateB.compareTo(dateA);
      });

    int streak = 1;
    DateTime previousDate = DateTime.parse(sorted[0]['created_at'] as String);

    for (int i = 1; i < sorted.length; i++) {
      final currentDate = DateTime.parse(sorted[i]['created_at'] as String);
      final difference = previousDate.difference(currentDate).inDays;

      // If consecutive days, continue streak
      if (difference == 1) {
        streak++;
        previousDate = currentDate;
      } else {
        break;
      }
    }

    return streak;
  }

  /// Check if user has 2 consecutive weeks with >=85% consistency
  bool _hasConsistentStreak(List<Map<String, dynamic>> workouts) {
    if (workouts.length < 12) return false; // Need at least 12 workouts for 2 weeks

    // Group workouts by week
    final now = DateTime.now();
    final weekGroups = <int, List<DateTime>>{};

    for (final workout in workouts) {
      final date = DateTime.parse(workout['created_at'] as String);
      final weekNumber = now.difference(date).inDays ~/ 7;
      weekGroups.putIfAbsent(weekNumber, () => []).add(date);
    }

    // Check for 2 consecutive weeks with >=6 workouts (85% of 7 days)
    for (int i = 0; i < weekGroups.length - 1; i++) {
      final week1 = weekGroups[i]?.length ?? 0;
      final week2 = weekGroups[i + 1]?.length ?? 0;

      if (week1 >= 6 && week2 >= 6) {
        return true;
      }
    }

    return false;
  }
}
