/// Achievement/Badge model
class Achievement {
  final String id;
  final String userId;
  final String badgeKey;
  final DateTime earnedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.badgeKey,
    required this.earnedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      badgeKey: json['badge_key'] as String,
      earnedAt: DateTime.parse(json['earned_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'badge_key': badgeKey,
      'earned_at': earnedAt.toIso8601String(),
    };
  }
}

/// Leaderboard entry model
class LeaderboardEntry {
  final String userId;
  final String displayName;
  final int xpThisWeek;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.xpThisWeek,
    required this.rank,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, String currentUserId) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String,
      xpThisWeek: json['xp_this_week'] as int,
      rank: json['rank'] as int? ?? 0,
      isCurrentUser: json['user_id'] == currentUserId,
    );
  }
}

/// User gamification stats
class UserGamificationStats {
  final int totalXp;
  final int level;
  final int xpThisWeek;
  final int xpToNextLevel;
  final double progressToNextLevel;
  final String levelTitle;
  final int totalAchievements;
  final int currentStreak;
  final double challengeCompletionRate;

  const UserGamificationStats({
    required this.totalXp,
    required this.level,
    required this.xpThisWeek,
    required this.xpToNextLevel,
    required this.progressToNextLevel,
    required this.levelTitle,
    required this.totalAchievements,
    required this.currentStreak,
    required this.challengeCompletionRate,
  });

  UserGamificationStats copyWith({
    int? totalXp,
    int? level,
    int? xpThisWeek,
    int? xpToNextLevel,
    double? progressToNextLevel,
    String? levelTitle,
    int? totalAchievements,
    int? currentStreak,
    double? challengeCompletionRate,
  }) {
    return UserGamificationStats(
      totalXp: totalXp ?? this.totalXp,
      level: level ?? this.level,
      xpThisWeek: xpThisWeek ?? this.xpThisWeek,
      xpToNextLevel: xpToNextLevel ?? this.xpToNextLevel,
      progressToNextLevel: progressToNextLevel ?? this.progressToNextLevel,
      levelTitle: levelTitle ?? this.levelTitle,
      totalAchievements: totalAchievements ?? this.totalAchievements,
      currentStreak: currentStreak ?? this.currentStreak,
      challengeCompletionRate: challengeCompletionRate ?? this.challengeCompletionRate,
    );
  }
}
