import 'package:flutter/material.dart';
import '../../core/utils/unit_converter.dart';

/// User profile model
class UserProfile {
  final String id;
  final String? displayName;
  final String? email;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final String? biologicalSex;
  final double? heightCm;
  final double? weightKg;
  final String trainingExperience;
  final String preferredUnits;
  final List<String> goals;
  final int xpTotal;
  final int level;
  final NotificationSettings notifications;
  final PrivacySettings privacy;
  final AppPreferences preferences;
  final DateTime createdAt;
  final DateTime? lastSeenAt;

  const UserProfile({
    required this.id,
    this.displayName,
    this.email,
    this.avatarUrl,
    this.dateOfBirth,
    this.biologicalSex,
    this.heightCm,
    this.weightKg,
    this.trainingExperience = 'Beginner',
    this.preferredUnits = 'metric',
    this.goals = const [],
    this.xpTotal = 0,
    this.level = 1,
    required this.notifications,
    required this.privacy,
    required this.preferences,
    required this.createdAt,
    this.lastSeenAt,
  });

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int age = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  String get displayHeight {
    if (heightCm == null) return 'Not set';
    if (preferredUnits == 'imperial') {
      return UnitConverter.formatHeightImperial(heightCm!);
    }
    return UnitConverter.formatHeightMetric(heightCm!);
  }

  String get displayWeight {
    if (weightKg == null) return 'Not set';
    if (preferredUnits == 'imperial') {
      return UnitConverter.formatWeightImperial(weightKg!);
    }
    return UnitConverter.formatWeightMetric(weightKg!);
  }

  String get initials {
    if (displayName == null || displayName!.isEmpty) return '?';
    final parts = displayName!.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  UserProfile copyWith({
    String? id,
    String? displayName,
    String? email,
    String? avatarUrl,
    DateTime? dateOfBirth,
    String? biologicalSex,
    double? heightCm,
    double? weightKg,
    String? trainingExperience,
    String? preferredUnits,
    List<String>? goals,
    int? xpTotal,
    int? level,
    NotificationSettings? notifications,
    PrivacySettings? privacy,
    AppPreferences? preferences,
    DateTime? createdAt,
    DateTime? lastSeenAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      trainingExperience: trainingExperience ?? this.trainingExperience,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      goals: goals ?? this.goals,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      notifications: notifications ?? this.notifications,
      privacy: privacy ?? this.privacy,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, String? email) {
    return UserProfile(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      email: email,
      avatarUrl: json['avatar_url'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      biologicalSex: json['biological_sex'] as String?,
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      trainingExperience: json['training_experience'] as String? ?? 'Beginner',
      preferredUnits: json['preferred_units'] as String? ?? 'metric',
      goals: (json['goals'] as List<dynamic>?)?.cast<String>() ?? [],
      xpTotal: json['xp_total'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      notifications: NotificationSettings.fromJson(json),
      privacy: PrivacySettings.fromJson(json),
      preferences: AppPreferences.fromJson(json),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastSeenAt: json['last_seen_at'] != null
          ? DateTime.parse(json['last_seen_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'date_of_birth': dateOfBirth?.toIso8601String().split('T')[0],
      'biological_sex': biologicalSex,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'training_experience': trainingExperience,
      'preferred_units': preferredUnits,
      'goals': goals,
      'xp_total': xpTotal,
      'level': level,
      ...notifications.toJson(),
      ...privacy.toJson(),
      ...preferences.toJson(),
      'created_at': createdAt.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
    };
  }
}

/// Notification settings model
class NotificationSettings {
  final bool workoutReminder;
  final bool streakReminder;
  final bool achievementUnlock;
  final bool weeklySummary;
  final TimeOfDay reminderTime;

  const NotificationSettings({
    required this.workoutReminder,
    required this.streakReminder,
    required this.achievementUnlock,
    required this.weeklySummary,
    required this.reminderTime,
  });

  static NotificationSettings get defaults => const NotificationSettings(
        workoutReminder: true,
        streakReminder: true,
        achievementUnlock: true,
        weeklySummary: true,
        reminderTime: TimeOfDay(hour: 19, minute: 0),
      );

  NotificationSettings copyWith({
    bool? workoutReminder,
    bool? streakReminder,
    bool? achievementUnlock,
    bool? weeklySummary,
    TimeOfDay? reminderTime,
  }) {
    return NotificationSettings(
      workoutReminder: workoutReminder ?? this.workoutReminder,
      streakReminder: streakReminder ?? this.streakReminder,
      achievementUnlock: achievementUnlock ?? this.achievementUnlock,
      weeklySummary: weeklySummary ?? this.weeklySummary,
      reminderTime: reminderTime ?? this.reminderTime,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    final timeString = json['notification_reminder_time'] as String?;
    TimeOfDay reminderTime = const TimeOfDay(hour: 19, minute: 0);

    if (timeString != null) {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        reminderTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 19,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    return NotificationSettings(
      workoutReminder: json['notification_workout_reminder'] as bool? ?? true,
      streakReminder: json['notification_streak_reminder'] as bool? ?? true,
      achievementUnlock: json['notification_achievement'] as bool? ?? true,
      weeklySummary: json['notification_weekly_summary'] as bool? ?? true,
      reminderTime: reminderTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'notification_workout_reminder': workoutReminder,
      'notification_streak_reminder': streakReminder,
      'notification_achievement': achievementUnlock,
      'notification_weekly_summary': weeklySummary,
      'notification_reminder_time':
          '${reminderTime.hour.toString().padLeft(2, '0')}:${reminderTime.minute.toString().padLeft(2, '0')}:00',
    };
  }
}

/// Privacy settings model
class PrivacySettings {
  final bool shareProgress;
  final bool appearOnLeaderboard;

  const PrivacySettings({
    required this.shareProgress,
    required this.appearOnLeaderboard,
  });

  static PrivacySettings get defaults => const PrivacySettings(
        shareProgress: false,
        appearOnLeaderboard: true,
      );

  PrivacySettings copyWith({
    bool? shareProgress,
    bool? appearOnLeaderboard,
  }) {
    return PrivacySettings(
      shareProgress: shareProgress ?? this.shareProgress,
      appearOnLeaderboard: appearOnLeaderboard ?? this.appearOnLeaderboard,
    );
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      shareProgress: json['privacy_share_progress'] as bool? ?? false,
      appearOnLeaderboard: json['privacy_appear_on_leaderboard'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacy_share_progress': shareProgress,
      'privacy_appear_on_leaderboard': appearOnLeaderboard,
    };
  }
}

/// App preferences model
class AppPreferences {
  final bool voiceGuidanceEnabled;
  final String cameraQuality;
  final String inferenceMode;
  final String language;

  const AppPreferences({
    required this.voiceGuidanceEnabled,
    required this.cameraQuality,
    required this.inferenceMode,
    required this.language,
  });

  static AppPreferences get defaults => const AppPreferences(
        voiceGuidanceEnabled: true,
        cameraQuality: 'medium',
        inferenceMode: 'auto',
        language: 'en',
      );

  AppPreferences copyWith({
    bool? voiceGuidanceEnabled,
    String? cameraQuality,
    String? inferenceMode,
    String? language,
  }) {
    return AppPreferences(
      voiceGuidanceEnabled: voiceGuidanceEnabled ?? this.voiceGuidanceEnabled,
      cameraQuality: cameraQuality ?? this.cameraQuality,
      inferenceMode: inferenceMode ?? this.inferenceMode,
      language: language ?? this.language,
    );
  }

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    return AppPreferences(
      voiceGuidanceEnabled: json['voice_guidance_enabled'] as bool? ?? true,
      cameraQuality: json['camera_quality'] as String? ?? 'medium',
      inferenceMode: json['inference_mode'] as String? ?? 'auto',
      language: json['language'] as String? ?? 'en',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'voice_guidance_enabled': voiceGuidanceEnabled,
      'camera_quality': cameraQuality,
      'inference_mode': inferenceMode,
      'language': language,
    };
  }
}
