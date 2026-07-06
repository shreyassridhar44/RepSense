import 'package:flutter/material.dart';

class AchievementConstants {
  AchievementConstants._();

  static const Map<String, Map<String, dynamic>> badges = {
    'first_workout': {
      'icon': Icons.emoji_events_rounded,
      'label': 'First Rep',
      'description': 'Completed your first workout',
      'tier': 'bronze',
    },
    '100_reps': {
      'icon': Icons.fitness_center_rounded,
      'label': 'Century Club',
      'description': 'Completed 100 total reps',
      'tier': 'bronze',
    },
    '1000_reps': {
      'icon': Icons.military_tech_rounded,
      'label': 'Rep Legend',
      'description': 'Completed 1000 total reps',
      'tier': 'gold',
    },
    '7_day_streak': {
      'icon': Icons.local_fire_department_rounded,
      'label': 'Week Warrior',
      'description': 'Trained for 7 consecutive days',
      'tier': 'silver',
    },
    '30_day_streak': {
      'icon': Icons.local_fire_department_rounded,
      'label': '30-Day Warrior',
      'description': 'Trained for 30 consecutive days',
      'tier': 'gold',
    },
    'perfect_form': {
      'icon': Icons.stars_rounded,
      'label': 'Perfect Form',
      'description': 'Achieved 100% form score',
      'tier': 'gold',
    },
    'balanced_form': {
      'icon': Icons.balance_rounded,
      'label': 'Balanced Form',
      'description': 'Maintained consistent form scores',
      'tier': 'silver',
    },
    'consistent': {
      'icon': Icons.calendar_month_rounded,
      'label': 'Consistency King',
      'description': 'Trained every day this week',
      'tier': 'silver',
    },
    'level_5': {
      'icon': Icons.workspace_premium_rounded,
      'label': 'Competitor',
      'description': 'Reached level 5',
      'tier': 'silver',
    },
    'level_10': {
      'icon': Icons.workspace_premium_rounded,
      'label': 'Elite Athlete',
      'description': 'Reached level 10',
      'tier': 'gold',
    },
    'level_20': {
      'icon': Icons.workspace_premium_rounded,
      'label': 'Legend',
      'description': 'Reached level 20',
      'tier': 'platinum',
    },
    'daily_challenge_7': {
      'icon': Icons.assignment_turned_in_rounded,
      'label': 'Challenge Crusher',
      'description': 'Completed 7 daily challenges',
      'tier': 'silver',
    },
    'daily_challenge_30': {
      'icon': Icons.assignment_turned_in_rounded,
      'label': 'Challenge Master',
      'description': 'Completed 30 daily challenges',
      'tier': 'gold',
    },
  };

  static Map<String, dynamic> getBadgeInfo(String badgeKey) {
    if (badges.containsKey(badgeKey)) {
      return badges[badgeKey]!;
    }
    
    // Fallback for unknown badges
    return {
      'icon': Icons.emoji_events_rounded,
      'label': _formatBadgeKey(badgeKey),
      'description': 'Achievement unlocked',
    };
  }

  static IconData getIcon(String badgeKey) {
    return getBadgeInfo(badgeKey)['icon'] as IconData;
  }

  static String getLabel(String badgeKey) {
    return getBadgeInfo(badgeKey)['label'] as String;
  }

  static String getDescription(String badgeKey) {
    return getBadgeInfo(badgeKey)['description'] as String;
  }

  static String getTier(String badgeKey) {
    return getBadgeInfo(badgeKey)['tier'] as String? ?? 'bronze';
  }

  static Color getTierColor(String tier) {
    switch (tier) {
      case 'bronze':
        return const Color(0xFFCD7F32);
      case 'silver':
        return const Color(0xFFC0C0C0);
      case 'gold':
        return const Color(0xFFF59E0B);
      case 'platinum':
        return const Color(0xFFE5E7EB);
      default:
        return const Color(0xFF9CA3AF);
    }
  }

  static String _formatBadgeKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
