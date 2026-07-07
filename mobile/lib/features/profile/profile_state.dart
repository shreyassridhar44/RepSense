import '../../data/models/profile_models.dart';

enum ProfileStatus {
  initial,
  loading,
  loaded,
  saving,
  error,
  deletingAccount,
  exportingData,
}

/// State for profile and settings management
class ProfileState {
  final ProfileStatus status;
  final UserProfile? profile;
  final String? errorMessage;
  final bool isSaving;
  final bool hasUnsavedChanges;

  // Edit state - mirrors profile fields
  final String? editDisplayName;
  final DateTime? editDateOfBirth;
  final String? editBiologicalSex;
  final double? editHeightCm;
  final double? editWeightKg;
  final String? editTrainingExperience;
  final List<String> editGoals;
  final String editPreferredUnits;

  // Avatar state
  final String? pendingAvatarBase64;
  final bool isUploadingAvatar;

  // Settings
  final NotificationSettings editNotifications;
  final PrivacySettings editPrivacy;
  final AppPreferences editPreferences;

  // Section-specific saving states
  final bool isSavingPersonalInfo;
  final bool isSavingMeasurements;
  final bool isSavingNotifications;
  final bool isSavingPrivacy;
  final bool isSavingPreferences;

  const ProfileState({
    this.status = ProfileStatus.initial,
    this.profile,
    this.errorMessage,
    this.isSaving = false,
    this.hasUnsavedChanges = false,
    this.editDisplayName,
    this.editDateOfBirth,
    this.editBiologicalSex,
    this.editHeightCm,
    this.editWeightKg,
    this.editTrainingExperience,
    this.editGoals = const [],
    this.editPreferredUnits = 'metric',
    this.pendingAvatarBase64,
    this.isUploadingAvatar = false,
    this.editNotifications = const NotificationSettings(
      workoutReminder: true,
      streakReminder: true,
      achievementUnlock: true,
      weeklySummary: true,
      reminderTime: TimeOfDay(hour: 19, minute: 0),
    ),
    this.editPrivacy = const PrivacySettings(
      shareProgress: false,
      appearOnLeaderboard: true,
    ),
    this.editPreferences = const AppPreferences(
      voiceGuidanceEnabled: true,
      cameraQuality: 'medium',
      inferenceMode: 'auto',
      language: 'en',
    ),
    this.isSavingPersonalInfo = false,
    this.isSavingMeasurements = false,
    this.isSavingNotifications = false,
    this.isSavingPrivacy = false,
    this.isSavingPreferences = false,
  });

  // Derived getters
  bool get isLoading => status == ProfileStatus.loading;
  bool get isLoaded => status == ProfileStatus.loaded;
  bool get hasError => status == ProfileStatus.error;
  bool get isDeletingAccount => status == ProfileStatus.deletingAccount;
  bool get isExportingData => status == ProfileStatus.exportingData;

  bool get hasPersonalInfoChanges {
    if (profile == null) return false;
    return editDisplayName != profile!.displayName ||
        editDateOfBirth != profile!.dateOfBirth ||
        editBiologicalSex != profile!.biologicalSex ||
        editTrainingExperience != profile!.trainingExperience ||
        !_listsEqual(editGoals, profile!.goals);
  }

  bool get hasMeasurementChanges {
    if (profile == null) return false;
    return editHeightCm != profile!.heightCm ||
        editWeightKg != profile!.weightKg ||
        editPreferredUnits != profile!.preferredUnits;
  }

  bool get hasNotificationChanges {
    if (profile == null) return false;
    return editNotifications.workoutReminder != profile!.notifications.workoutReminder ||
        editNotifications.streakReminder != profile!.notifications.streakReminder ||
        editNotifications.achievementUnlock != profile!.notifications.achievementUnlock ||
        editNotifications.weeklySummary != profile!.notifications.weeklySummary ||
        editNotifications.reminderTime != profile!.notifications.reminderTime;
  }

  bool get hasPrivacyChanges {
    if (profile == null) return false;
    return editPrivacy.shareProgress != profile!.privacy.shareProgress ||
        editPrivacy.appearOnLeaderboard != profile!.privacy.appearOnLeaderboard;
  }

  bool get hasPreferenceChanges {
    if (profile == null) return false;
    return editPreferences.voiceGuidanceEnabled != profile!.preferences.voiceGuidanceEnabled ||
        editPreferences.cameraQuality != profile!.preferences.cameraQuality ||
        editPreferences.inferenceMode != profile!.preferences.inferenceMode ||
        editPreferences.language != profile!.preferences.language;
  }

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  ProfileState copyWith({
    ProfileStatus? status,
    UserProfile? profile,
    String? errorMessage,
    bool? isSaving,
    bool? hasUnsavedChanges,
    String? editDisplayName,
    DateTime? editDateOfBirth,
    String? editBiologicalSex,
    double? editHeightCm,
    double? editWeightKg,
    String? editTrainingExperience,
    List<String>? editGoals,
    String? editPreferredUnits,
    String? pendingAvatarBase64,
    bool? isUploadingAvatar,
    NotificationSettings? editNotifications,
    PrivacySettings? editPrivacy,
    AppPreferences? editPreferences,
    bool? isSavingPersonalInfo,
    bool? isSavingMeasurements,
    bool? isSavingNotifications,
    bool? isSavingPrivacy,
    bool? isSavingPreferences,
  }) {
    return ProfileState(
      status: status ?? this.status,
      profile: profile ?? this.profile,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      editDisplayName: editDisplayName ?? this.editDisplayName,
      editDateOfBirth: editDateOfBirth ?? this.editDateOfBirth,
      editBiologicalSex: editBiologicalSex ?? this.editBiologicalSex,
      editHeightCm: editHeightCm ?? this.editHeightCm,
      editWeightKg: editWeightKg ?? this.editWeightKg,
      editTrainingExperience: editTrainingExperience ?? this.editTrainingExperience,
      editGoals: editGoals ?? this.editGoals,
      editPreferredUnits: editPreferredUnits ?? this.editPreferredUnits,
      pendingAvatarBase64: pendingAvatarBase64,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      editNotifications: editNotifications ?? this.editNotifications,
      editPrivacy: editPrivacy ?? this.editPrivacy,
      editPreferences: editPreferences ?? this.editPreferences,
      isSavingPersonalInfo: isSavingPersonalInfo ?? this.isSavingPersonalInfo,
      isSavingMeasurements: isSavingMeasurements ?? this.isSavingMeasurements,
      isSavingNotifications: isSavingNotifications ?? this.isSavingNotifications,
      isSavingPrivacy: isSavingPrivacy ?? this.isSavingPrivacy,
      isSavingPreferences: isSavingPreferences ?? this.isSavingPreferences,
    );
  }
}
