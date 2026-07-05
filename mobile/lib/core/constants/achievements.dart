import 'package:flutter/material.dart';

class AchievementConstants {
  AchievementConstants._();

  static const Map<String, Map<String, dynamic>> badges = {
    '100_reps': {
      'icon': Icons.fitness_center_rounded,
      'label': 'Century Club',
      'description': 'Completed 100 total reps',
    },
    '30_day_streak': {
      'icon': Icons.local_fire_department_rounded,
      'label': '30-Day Warrior',
      'description': 'Trained for 30 consecutive days',
    },
    '7_day_streak': {
      'icon': Icons.local_fire_department_rounded,
      'label': 'Week Warrior',
      'description': 'Trained for 7 consecutive days',
    },
    'perfect_form': {
      'icon': Icons.stars_rounded,
      'label': 'Perfect Form',
      'description': 'Achieved 100% form score',
    },
    'first_workout': {
      'icon': Icons.emoji_events_rounded,
      'label': 'First Rep',
      'description': 'Completed your first workout',
    },
    'consistent': {
      'icon': Icons.calendar_month_rounded,
      'label': 'Consistency King',
      'description': 'Trained every day this week',
    },
    'balanced_form': {
      'icon': Icons.balance_rounded,
      'label': 'Balanced Form',
      'description': 'Maintained consistent form scores',
    },
    '1000_reps': {
      'icon': Icons.military_tech_rounded,
      'label': 'Rep Legend',
      'description': 'Completed 1000 total reps',
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

  static String _formatBadgeKey(String key) {
    // Convert snake_case to Title Case
    return key
        .split('_')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }
}
