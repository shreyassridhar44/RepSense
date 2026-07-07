import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io' show Platform;
import '../../core/utils/app_logger.dart';
import '../../data/models/profile_models.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/supabase/supabase_service.dart';
import '../coach/services/image_picker_service.dart';
import 'profile_state.dart';

/// Notifier for profile and settings management
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository _repository;
  final String _userId;
  final ImagePickerService _imagePickerService;
  Timer? _debounceTimer;

  ProfileNotifier({
    required ProfileRepository repository,
    required String userId,
    ImagePickerService? imagePickerService,
  })  : _repository = repository,
        _userId = userId,
        _imagePickerService = imagePickerService ?? ImagePickerService(),
        super(const ProfileState());

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load profile data
  Future<void> load() async {
    if (state.status == ProfileStatus.loading) return;

    try {
      state = state.copyWith(status: ProfileStatus.loading);
      AppLogger.info('📋 Loading profile');

      final profile = await _repository.getProfile(_userId);

      // Initialize edit fields with current values
      state = state.copyWith(
        status: ProfileStatus.loaded,
        profile: profile,
        editDisplayName: profile.displayName,
        editDateOfBirth: profile.dateOfBirth,
        editBiologicalSex: profile.biologicalSex,
        editHeightCm: profile.heightCm,
        editWeightKg: profile.weightKg,
        editTrainingExperience: profile.trainingExperience,
        editGoals: List.from(profile.goals),
        editPreferredUnits: profile.preferredUnits,
        editNotifications: profile.notifications,
        editPrivacy: profile.privacy,
        editPreferences: profile.preferences,
      );

      AppLogger.info('✅ Profile loaded');
    } catch (e, stack) {
      AppLogger.error('Failed to load profile', e, stack);
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to load profile',
      );
    }
  }

  /// Refresh profile without changing status
  Future<void> refresh() async {
    try {
      final profile = await _repository.getProfile(_userId);
      state = state.copyWith(profile: profile);
    } catch (e) {
      AppLogger.warning('Failed to refresh profile', e);
    }
  }

  // Field update methods (state only, no network)
  void updateDisplayName(String value) {
    state = state.copyWith(editDisplayName: value.trim());
  }

  void updateDateOfBirth(DateTime? value) {
    state = state.copyWith(editDateOfBirth: value);
  }

  void updateBiologicalSex(String? value) {
    state = state.copyWith(editBiologicalSex: value);
  }

  void updateHeightCm(double? value) {
    state = state.copyWith(editHeightCm: value);
  }

  void updateWeightKg(double? value) {
    state = state.copyWith(editWeightKg: value);
  }

  void updateTrainingExperience(String value) {
    state = state.copyWith(editTrainingExperience: value);
  }

  void toggleGoal(String goal) {
    final goals = List<String>.from(state.editGoals);
    if (goals.contains(goal)) {
      if (goals.length > 1) {
        goals.remove(goal);
      }
    } else {
      goals.add(goal);
    }
    state = state.copyWith(editGoals: goals);
  }

  void setPreferredUnits(String units) {
    state = state.copyWith(editPreferredUnits: units);
  }

  void updateNotifications(NotificationSettings settings) {
    state = state.copyWith(editNotifications: settings);
  }

  void toggleNotification(String key) {
    final current = state.editNotifications;
    NotificationSettings updated;

    switch (key) {
      case 'workoutReminder':
        updated = current.copyWith(workoutReminder: !current.workoutReminder);
        break;
      case 'streakReminder':
        updated = current.copyWith(streakReminder: !current.streakReminder);
        break;
      case 'achievementUnlock':
        updated = current.copyWith(achievementUnlock: !current.achievementUnlock);
        break;
      case 'weeklySummary':
        updated = current.copyWith(weeklySummary: !current.weeklySummary);
        break;
      default:
        return;
    }

    state = state.copyWith(editNotifications: updated);
    _debouncedSave(() => saveNotificationsSettings());
  }

  void updateReminderTime(TimeOfDay time) {
    final updated = state.editNotifications.copyWith(reminderTime: time);
    state = state.copyWith(editNotifications: updated);
    _debouncedSave(() => saveNotificationsSettings());
  }

  void updatePrivacy(PrivacySettings settings) {
    state = state.copyWith(editPrivacy: settings);
  }

  void togglePrivacy(String key) {
    final current = state.editPrivacy;
    PrivacySettings updated;

    switch (key) {
      case 'shareProgress':
        updated = current.copyWith(shareProgress: !current.shareProgress);
        break;
      case 'appearOnLeaderboard':
        updated = current.copyWith(appearOnLeaderboard: !current.appearOnLeaderboard);
        break;
      default:
        return;
    }

    state = state.copyWith(editPrivacy: updated);
    _debouncedSave(() => savePrivacySettings());
  }

  void updatePreferences(AppPreferences prefs) {
    state = state.copyWith(editPreferences: prefs);
  }

  void setCameraQuality(String quality) {
    final updated = state.editPreferences.copyWith(cameraQuality: quality);
    state = state.copyWith(editPreferences: updated);
    _debouncedSave(() => savePreferences());
  }

  void setInferenceMode(String mode) {
    final updated = state.editPreferences.copyWith(inferenceMode: mode);
    state = state.copyWith(editPreferences: updated);
    _debouncedSave(() => savePreferences());
  }

  void toggleVoiceGuidance() {
    final updated = state.editPreferences.copyWith(
      voiceGuidanceEnabled: !state.editPreferences.voiceGuidanceEnabled,
    );
    state = state.copyWith(editPreferences: updated);
    _debouncedSave(() => savePreferences());
  }

  /// Debounced save (500ms)
  void _debouncedSave(Function() saveFn) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), saveFn);
  }

  // Save methods
  Future<void> savePersonalInfo() async {
    if (state.isSavingPersonalInfo) return;

    try {
      state = state.copyWith(isSavingPersonalInfo: true);
      AppLogger.info('💾 Saving personal info');

      final updates = <String, dynamic>{
        'display_name': state.editDisplayName,
        'date_of_birth': state.editDateOfBirth?.toIso8601String().split('T')[0],
        'biological_sex': state.editBiologicalSex,
        'training_experience': state.editTrainingExperience,
        'goals': state.editGoals,
      };

      await _repository.updateProfile(_userId, updates);

      // Reload profile
      await refresh();

      state = state.copyWith(isSavingPersonalInfo: false);
      AppLogger.info('✅ Personal info saved');
    } catch (e, stack) {
      AppLogger.error('Failed to save personal info', e, stack);
      state = state.copyWith(
        isSavingPersonalInfo: false,
        errorMessage: 'Failed to save changes',
      );
      rethrow;
    }
  }

  Future<void> saveMeasurements() async {
    if (state.isSavingMeasurements) return;

    try {
      state = state.copyWith(isSavingMeasurements: true);
      AppLogger.info('💾 Saving measurements');

      final updates = <String, dynamic>{
        'height_cm': state.editHeightCm,
        'weight_kg': state.editWeightKg,
        'preferred_units': state.editPreferredUnits,
      };

      await _repository.updateProfile(_userId, updates);
      await refresh();

      state = state.copyWith(isSavingMeasurements: false);
      AppLogger.info('✅ Measurements saved');
    } catch (e, stack) {
      AppLogger.error('Failed to save measurements', e, stack);
      state = state.copyWith(
        isSavingMeasurements: false,
        errorMessage: 'Failed to save changes',
      );
      rethrow;
    }
  }

  Future<void> saveNotificationsSettings() async {
    if (state.isSavingNotifications) return;

    try {
      state = state.copyWith(isSavingNotifications: true);

      final updates = state.editNotifications.toJson();
      await _repository.updateProfile(_userId, updates);
      await refresh();

      state = state.copyWith(isSavingNotifications: false);
    } catch (e) {
      AppLogger.error('Failed to save notifications', e);
      state = state.copyWith(isSavingNotifications: false);
    }
  }

  Future<void> savePrivacySettings() async {
    if (state.isSavingPrivacy) return;

    try {
      state = state.copyWith(isSavingPrivacy: true);

      final updates = state.editPrivacy.toJson();
      await _repository.updateProfile(_userId, updates);

      // Update leaderboard visibility
      await _repository.updateLeaderboardVisibility(
        _userId,
        !state.editPrivacy.appearOnLeaderboard,
      );

      await refresh();
      state = state.copyWith(isSavingPrivacy: false);
    } catch (e) {
      AppLogger.error('Failed to save privacy', e);
      state = state.copyWith(isSavingPrivacy: false);
    }
  }

  Future<void> savePreferences() async {
    if (state.isSavingPreferences) return;

    try {
      state = state.copyWith(isSavingPreferences: true);

      final updates = state.editPreferences.toJson();
      await _repository.updateProfile(_userId, updates);
      await refresh();

      state = state.copyWith(isSavingPreferences: false);
    } catch (e) {
      AppLogger.error('Failed to save preferences', e);
      state = state.copyWith(isSavingPreferences: false);
    }
  }

  // Avatar methods
  Future<void> pickAndUploadAvatar(ImageSource source) async {
    try {
      state = state.copyWith(isUploadingAvatar: true);
      AppLogger.info('📸 Picking avatar from $source');

      // Pick image
      final imageBytes = await _imagePickerService.pickAndProcessImage(source);
      if (imageBytes == null) {
        state = state.copyWith(isUploadingAvatar: false);
        return;
      }

      // Show preview immediately
      final base64 = base64Encode(imageBytes);
      state = state.copyWith(pendingAvatarBase64: base64);

      // Upload
      final url = await _repository.uploadAvatar(_userId, imageBytes);

      // Update profile
      await refresh();

      state = state.copyWith(
        pendingAvatarBase64: null,
        isUploadingAvatar: false,
      );

      AppLogger.info('✅ Avatar uploaded');
    } catch (e, stack) {
      AppLogger.error('Failed to upload avatar', e, stack);
      state = state.copyWith(
        pendingAvatarBase64: null,
        isUploadingAvatar: false,
        errorMessage: 'Failed to upload photo',
      );
    }
  }

  Future<void> removeAvatar() async {
    try {
      AppLogger.info('🗑️ Removing avatar');
      await _repository.deleteAvatar(_userId);
      await refresh();
      AppLogger.info('✅ Avatar removed');
    } catch (e, stack) {
      AppLogger.error('Failed to remove avatar', e, stack);
      state = state.copyWith(errorMessage: 'Failed to remove photo');
    }
  }

  // Account methods
  Future<void> changePassword(String currentPassword, String newPassword) async {
    try {
      AppLogger.info('🔐 Changing password');

      // Verify current password first
      final email = state.profile?.email;
      if (email == null) throw Exception('Email not found');

      // Re-authenticate
      await SupabaseService.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update password
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      AppLogger.info('✅ Password changed');
    } catch (e, stack) {
      AppLogger.error('Failed to change password', e, stack);
      if (e.toString().contains('Invalid')) {
        throw Exception('Current password is incorrect');
      }
      throw Exception('Failed to change password');
    }
  }

  Future<void> changeEmail(String newEmail, String currentPassword) async {
    try {
      AppLogger.info('📧 Changing email');

      // Verify current password
      final email = state.profile?.email;
      if (email == null) throw Exception('Email not found');

      await SupabaseService.instance.client.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      // Update email (requires confirmation)
      await SupabaseService.instance.client.auth.updateUser(
        UserAttributes(email: newEmail),
      );

      AppLogger.info('✅ Confirmation email sent');
    } catch (e, stack) {
      AppLogger.error('Failed to change email', e, stack);
      if (e.toString().contains('Invalid')) {
        throw Exception('Current password is incorrect');
      }
      throw Exception('Failed to change email');
    }
  }

  Future<void> exportData() async {
    try {
      state = state.copyWith(status: ProfileStatus.exportingData);
      AppLogger.info('📦 Exporting user data');

      final jsonData = await _repository.exportUserData(_userId);

      // Get app info
      final packageInfo = await PackageInfo.fromPlatform();
      final fileName = 'repsense_data_export_${DateTime.now().millisecondsSinceEpoch}.json';

      // Share
      await Share.shareXFiles(
        [
          XFile.fromData(
            utf8.encode(jsonData),
            mimeType: 'application/json',
            name: fileName,
          ),
        ],
        subject: 'RepSense Data Export',
      );

      state = state.copyWith(status: ProfileStatus.loaded);
      AppLogger.info('✅ Data exported');
    } catch (e, stack) {
      AppLogger.error('Failed to export data', e, stack);
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to export data',
      );
      rethrow;
    }
  }

  Future<void> deleteAccount(String confirmationText) async {
    if (confirmationText != 'DELETE') {
      throw Exception('Confirmation text must be "DELETE"');
    }

    try {
      state = state.copyWith(status: ProfileStatus.deletingAccount);
      AppLogger.info('⚠️ Deleting account');

      await _repository.deleteAccount(_userId);

      AppLogger.info('✅ Account deleted');
    } catch (e, stack) {
      AppLogger.error('Failed to delete account', e, stack);
      state = state.copyWith(
        status: ProfileStatus.error,
        errorMessage: 'Failed to delete account — ${e.toString()}',
      );
      rethrow;
    }
  }

  Future<void> submitFeedback(String category, String message) async {
    try {
      AppLogger.info('📝 Submitting feedback');

      final packageInfo = await PackageInfo.fromPlatform();
      final deviceInfo = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';

      await _repository.submitFeedback(
        userId: _userId,
        category: category,
        message: message,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
        deviceInfo: deviceInfo,
      );

      AppLogger.info('✅ Feedback submitted');
    } catch (e, stack) {
      AppLogger.error('Failed to submit feedback', e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      AppLogger.info('👋 Signing out');

      // Sign out from Supabase
      await SupabaseService.instance.client.auth.signOut();

      AppLogger.info('✅ Signed out');
    } catch (e, stack) {
      AppLogger.error('Failed to sign out', e, stack);
      // Force sign out locally anyway
      await SupabaseService.instance.client.auth.signOut();
    }
  }

  void discardChanges() {
    if (state.profile == null) return;

    state = state.copyWith(
      editDisplayName: state.profile!.displayName,
      editDateOfBirth: state.profile!.dateOfBirth,
      editBiologicalSex: state.profile!.biologicalSex,
      editHeightCm: state.profile!.heightCm,
      editWeightKg: state.profile!.weightKg,
      editTrainingExperience: state.profile!.trainingExperience,
      editGoals: List.from(state.profile!.goals),
      editPreferredUnits: state.profile!.preferredUnits,
      editNotifications: state.profile!.notifications,
      editPrivacy: state.profile!.privacy,
      editPreferences: state.profile!.preferences,
      hasUnsavedChanges: false,
    );
  }
}
