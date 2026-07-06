import '../../core/utils/app_logger.dart';
import '../supabase/supabase_service.dart';
import 'package:flutter/material.dart';

/// XP rewards for various actions
class XpRewards {
  static const int workoutCompleted = 50;
  static const int perfectFormRep = 5; // per rep with score >= 95
  static const int goodFormRep = 2; // per rep with score 70-94
  static const int newPersonalBest = 75;
  static const int streakMilestone7 = 100;
  static const int streakMilestone30 = 500;
  static const int dailyChallengeCompleted = 150;
  static const int firstWorkoutOfDay = 25;
  static const int consistencyBonus = 200;
  static const int badgeUnlocked = 100;
}

/// Level system with thresholds
class LevelSystem {
  static const List<int> _thresholds = [
    0, // Level 1
    200, // Level 2
    500, // Level 3
    1000, // Level 4
    1800, // Level 5
    2900, // Level 6
    4200, // Level 7
    5800, // Level 8
    7700, // Level 9
    10000, // Level 10
  ];

  static int levelForXp(int xp) {
    if (xp < 0) return 1;

    // Check defined thresholds
    for (int i = _thresholds.length - 1; i >= 0; i--) {
      if (xp >= _thresholds[i]) {
        return i + 1;
      }
    }

    // Beyond level 10
    if (xp >= _thresholds.last) {
      final beyondL10 = xp - _thresholds.last;
      return 10 + (beyondL10 / 3000).floor();
    }

    return 1;
  }

  static int xpForLevel(int level) {
    if (level <= 0) return 0;
    if (level <= _thresholds.length) {
      return _thresholds[level - 1];
    }

    // Beyond defined thresholds
    final levelsAbove10 = level - 10;
    return _thresholds.last + (levelsAbove10 * 3000);
  }

  static int xpToNextLevel(int currentXp) {
    final currentLevel = levelForXp(currentXp);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    return nextLevelXp - currentXp;
  }

  static double progressToNextLevel(int currentXp) {
    final currentLevel = levelForXp(currentXp);
    final currentLevelXp = xpForLevel(currentLevel);
    final nextLevelXp = xpForLevel(currentLevel + 1);
    final levelRange = nextLevelXp - currentLevelXp;

    if (levelRange == 0) return 0.0;

    final progress = (currentXp - currentLevelXp) / levelRange;
    return progress.clamp(0.0, 1.0);
  }

  static String levelTitle(int level) {
    if (level <= 0) return 'Beginner';
    if (level == 1) return 'Beginner';
    if (level == 2) return 'Rookie';
    if (level == 3) return 'Trainee';
    if (level == 4) return 'Athlete';
    if (level == 5) return 'Competitor';
    if (level == 6) return 'Contender';
    if (level == 7) return 'Champion';
    if (level == 8) return 'Elite';
    if (level == 9) return 'Master';
    return 'Legend';
  }

  static Color levelColor(int level) {
    if (level <= 3) return const Color(0xFF9CA3AF); // Grey
    if (level <= 5) return const Color(0xFF10B981); // Emerald
    if (level <= 7) return const Color(0xFF3B82F6); // Electric Blue
    if (level <= 9) return const Color(0xFF8B5CF6); // Violet
    return const Color(0xFFF59E0B); // Amber (gold)
  }
}

/// XP service for awarding and managing XP
class XpService {
  final SupabaseService _supabase;

  XpService({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Award XP to a user
  Future<XpResult> awardXp({
    required String userId,
    required int amount,
    required String reason,
  }) async {
    try {
      AppLogger.info('⭐ Awarding $amount XP to $userId for $reason');

      // Call RPC function for atomic operation
      final result = await _supabase.client.rpc(
        'award_xp',
        params: {
          'p_user_id': userId,
          'p_amount': amount,
        },
      );

      if (result == null || result.isEmpty) {
        throw Exception('No result from award_xp');
      }

      final data = result[0] as Map<String, dynamic>;
      final newTotalXp = data['new_total'] as int;
      final newWeekXp = data['new_week'] as int;

      // Compute levels
      final previousLevel = LevelSystem.levelForXp(newTotalXp - amount);
      final newLevel = LevelSystem.levelForXp(newTotalXp);
      final levelledUp = newLevel > previousLevel;

      final xpResult = XpResult(
        xpAwarded: amount,
        newTotalXp: newTotalXp,
        previousLevel: previousLevel,
        newLevel: newLevel,
        levelledUp: levelledUp,
        xpToNextLevel: LevelSystem.xpToNextLevel(newTotalXp),
        progressToNextLevel: LevelSystem.progressToNextLevel(newTotalXp),
      );

      AppLogger.info('✅ XP awarded: $amount, new total: $newTotalXp, level: $newLevel');
      return xpResult;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to award XP', e, stack);
      // Non-critical - return zero result
      return XpResult(
        xpAwarded: 0,
        newTotalXp: 0,
        previousLevel: 1,
        newLevel: 1,
        levelledUp: false,
        xpToNextLevel: 200,
        progressToNextLevel: 0.0,
      );
    }
  }

  /// Get weekly XP for a user
  Future<int> getWeeklyXp(String userId) async {
    try {
      final profile = await _supabase.getProfile(userId);
      return profile?['xp_this_week'] as int? ?? 0;
    } catch (e) {
      AppLogger.error('Failed to get weekly XP', e);
      return 0;
    }
  }
}

/// Result of awarding XP
class XpResult {
  final int xpAwarded;
  final int newTotalXp;
  final int previousLevel;
  final int newLevel;
  final bool levelledUp;
  final int xpToNextLevel;
  final double progressToNextLevel; // 0.0-1.0

  const XpResult({
    required this.xpAwarded,
    required this.newTotalXp,
    required this.previousLevel,
    required this.newLevel,
    required this.levelledUp,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
  });

  XpResult copyWith({
    int? xpAwarded,
    int? newTotalXp,
    int? previousLevel,
    int? newLevel,
    bool? levelledUp,
    int? xpToNextLevel,
    double? progressToNextLevel,
  }) {
    return XpResult(
      xpAwarded: xpAwarded ?? this.xpAwarded,
      newTotalXp: newTotalXp ?? this.newTotalXp,
      previousLevel: previousLevel ?? this.previousLevel,
      newLevel: newLevel ?? this.newLevel,
      levelledUp: levelledUp ?? this.levelledUp,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
    );
  }
}
