import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../../core/constants/app_config.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/profile_models.dart';
import '../supabase/supabase_service.dart';

/// Repository for profile and settings operations
class ProfileRepository {
  final SupabaseService _supabase;

  ProfileRepository({SupabaseService? supabase})
      : _supabase = supabase ?? SupabaseService.instance;

  /// Get user profile
  Future<UserProfile> getProfile(String userId) async {
    try {
      AppLogger.info('📋 Fetching profile for user: $userId');

      final profileData = await _supabase.getProfile(userId);
      final email = _supabase.currentUser?.email;

      if (profileData == null) {
        // Return default profile
        AppLogger.warning('Profile not found, returning defaults');
        return UserProfile(
          id: userId,
          email: email,
          notifications: NotificationSettings.defaults,
          privacy: PrivacySettings.defaults,
          preferences: AppPreferences.defaults,
          createdAt: DateTime.now(),
        );
      }

      final profile = UserProfile.fromJson(profileData, email);
      AppLogger.info('✅ Profile loaded successfully');
      return profile;
    } catch (e, stack) {
      AppLogger.error('Failed to get profile', e, stack);
      throw AppException('Failed to load profile');
    }
  }

  /// Update profile (partial update)
  Future<void> updateProfile(String userId, Map<String, dynamic> updates) async {
    try {
      AppLogger.info('💾 Updating profile: ${updates.keys.join(', ')}');

      await _supabase.client.from('profiles').upsert({
        'id': userId,
        ...updates,
      });

      AppLogger.info('✅ Profile updated successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to update profile', e, stack);
      throw AppException('Failed to save changes');
    }
  }

  /// Upload avatar image
  Future<String> uploadAvatar(String userId, Uint8List imageBytes) async {
    try {
      AppLogger.info('📸 Uploading avatar for user: $userId');

      final fileName = '$userId.jpg';

      // Upload to avatars bucket
      await _supabase.client.storage
          .from('avatars')
          .uploadBinary(fileName, imageBytes,
              fileOptions: const FileOptions(upsert: true));

      // Get public URL
      final url = _supabase.client.storage.from('avatars').getPublicUrl(fileName);

      // Add cache-busting timestamp
      final timestampedUrl = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update profile with new avatar URL
      await updateProfile(userId, {'avatar_url': timestampedUrl});

      AppLogger.info('✅ Avatar uploaded successfully');
      return timestampedUrl;
    } catch (e, stack) {
      AppLogger.error('Failed to upload avatar', e, stack);
      throw AppException('Couldn\'t upload photo — try again');
    }
  }

  /// Delete avatar
  Future<void> deleteAvatar(String userId) async {
    try {
      AppLogger.info('🗑️ Deleting avatar for user: $userId');

      final fileName = '$userId.jpg';

      // Delete from storage
      try {
        await _supabase.client.storage.from('avatars').remove([fileName]);
      } catch (e) {
        AppLogger.warning('Avatar file not found in storage', e);
        // Continue anyway
      }

      // Update profile
      await updateProfile(userId, {'avatar_url': null});

      AppLogger.info('✅ Avatar deleted successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to delete avatar', e, stack);
      throw AppException('Couldn\'t remove photo');
    }
  }

  /// Update last seen timestamp
  Future<void> updateLastSeen(String userId) async {
    try {
      await _supabase.client.from('profiles').update({
        'last_seen_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      // Silently ignore - non-critical
      AppLogger.debug('Failed to update last seen', e);
    }
  }

  /// Submit feedback
  Future<void> submitFeedback({
    required String userId,
    required String category,
    required String message,
    required String appVersion,
    required String deviceInfo,
  }) async {
    try {
      AppLogger.info('📝 Submitting feedback: $category');

      await _supabase.client.from('feedback').insert({
        'user_id': userId,
        'category': category,
        'message': message,
        'app_version': appVersion,
        'device_info': deviceInfo,
      });

      AppLogger.info('✅ Feedback submitted successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to submit feedback', e, stack);
      throw AppException('Couldn\'t send feedback — try again');
    }
  }

  /// Export user data
  Future<String> exportUserData(String userId) async {
    try {
      AppLogger.info('📦 Exporting user data');

      // Fetch all user data in parallel
      final results = await Future.wait([
        _supabase.client.from('profiles').select().eq('id', userId).single(),
        _supabase.client.from('workouts').select().eq('user_id', userId),
        _supabase.client.from('achievements').select().eq('user_id', userId),
        _supabase.client
            .from('daily_challenges')
            .select()
            .eq('user_id', userId),
      ]).timeout(const Duration(seconds: 30));

      final exportData = {
        'exported_at': DateTime.now().toIso8601String(),
        'user_id': userId,
        'profile': results[0],
        'workouts': results[1],
        'achievements': results[2],
        'daily_challenges': results[3],
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      AppLogger.info('✅ Data exported successfully');
      return jsonString;
    } catch (e, stack) {
      AppLogger.error('Failed to export data', e, stack);
      if (e.toString().contains('timeout')) {
        throw AppException('Export timed out — try again');
      }
      throw AppException('Failed to export data');
    }
  }

  /// Delete account (calls backend API)
  Future<void> deleteAccount(String userId) async {
    try {
      AppLogger.info('⚠️ Deleting account for user: $userId');

      // Get current session token
      final session = _supabase.client.auth.currentSession;
      if (session == null) {
        throw AppException('Not authenticated');
      }

      // Get backend URL from config
      final backendUrl = AppConfig.apiServiceUrl;
      
      // Call backend API delete-account endpoint using http package
      final url = Uri.parse('$backendUrl/account/delete');
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        throw AppException('Account deletion failed: ${response.body}');
      }

      // Sign out after successful deletion
      await _supabase.client.auth.signOut();

      AppLogger.info('✅ Account deleted successfully');
    } catch (e, stack) {
      AppLogger.error('Failed to delete account', e, stack);
      throw AppException('Couldn\'t delete account — ${e.toString()}');
    }
  }

  /// Update leaderboard visibility
  Future<void> updateLeaderboardVisibility(String userId, bool isHidden) async {
    try {
      final weekStart = DateTime.now().subtract(
        Duration(days: DateTime.now().weekday - 1),
      );

      await _supabase.client.from('leaderboard_weekly').update({
        'is_hidden': isHidden,
      }).eq('user_id', userId).eq(
            'week_start',
            weekStart.toIso8601String().split('T')[0],
          );
    } catch (e) {
      AppLogger.warning('Failed to update leaderboard visibility', e);
      // Non-critical
    }
  }
}
