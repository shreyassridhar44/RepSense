import 'package:equatable/equatable.dart';
import '../../../core/constants/achievements.dart';

class Achievement extends Equatable {
  final String badgeKey;
  final String label;
  final String description;
  final DateTime unlockedAt;

  const Achievement({
    required this.badgeKey,
    required this.label,
    required this.description,
    required this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    final badgeKey = json['badge_key'] as String;
    final badgeInfo = AchievementConstants.getBadgeInfo(badgeKey);
    
    return Achievement(
      badgeKey: badgeKey,
      label: badgeInfo['label'] as String,
      description: badgeInfo['description'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
    );
  }

  Achievement copyWith({
    String? badgeKey,
    String? label,
    String? description,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      badgeKey: badgeKey ?? this.badgeKey,
      label: label ?? this.label,
      description: description ?? this.description,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  @override
  List<Object?> get props => [badgeKey, label, description, unlockedAt];
}
