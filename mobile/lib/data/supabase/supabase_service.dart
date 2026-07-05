import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/app_exception.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    try {
      AppLogger.info('🔧 Initializing Supabase...');
      AppLogger.debug('Supabase URL: $url');
      
      await Supabase.initialize(
        url: url,
        anonKey: anonKey,
      );
      
      AppLogger.info('✅ Supabase initialized successfully');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize Supabase', e, stack);
      rethrow;
    }
  }

  // ---- Auth ----
  User? get currentUser => client.auth.currentUser;
  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  Future<AuthResponse> signUpWithEmail(String email, String password) async {
    try {
      AppLogger.info('🔐 Attempting sign up with email: $email');
      final response = await client.auth.signUp(email: email, password: password);
      
      if (response.user != null) {
        AppLogger.info('✅ Sign up successful for user: ${response.user!.id}');
      } else {
        AppLogger.warning('⚠️ Sign up response has no user');
      }
      
      return response;
    } catch (e, stack) {
      AppLogger.error('❌ Sign up failed for email: $email', e, stack);
      rethrow;
    }
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      AppLogger.info('🔐 Attempting sign in with email: $email');
      final response = await client.auth.signInWithPassword(email: email, password: password);
      
      if (response.user != null) {
        AppLogger.info('✅ Sign in successful for user: ${response.user!.id}');
      } else {
        AppLogger.warning('⚠️ Sign in response has no user');
      }
      
      return response;
    } catch (e, stack) {
      AppLogger.error('❌ Sign in failed for email: $email', e, stack);
      rethrow;
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      AppLogger.info('🔐 Attempting Google sign in');
      final result = await client.auth.signInWithOAuth(OAuthProvider.google);
      AppLogger.info('✅ Google sign in initiated: $result');
      return result;
    } catch (e, stack) {
      AppLogger.error('❌ Google sign in failed', e, stack);
      rethrow;
    }
  }

  Future<bool> signInWithApple() async {
    try {
      AppLogger.info('🔐 Attempting Apple sign in');
      final result = await client.auth.signInWithOAuth(OAuthProvider.apple);
      AppLogger.info('✅ Apple sign in initiated: $result');
      return result;
    } catch (e, stack) {
      AppLogger.error('❌ Apple sign in failed', e, stack);
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      final userId = currentUser?.id;
      AppLogger.info('🔐 Signing out user: $userId');
      await client.auth.signOut();
      AppLogger.info('✅ Sign out successful');
    } catch (e, stack) {
      AppLogger.error('❌ Sign out failed', e, stack);
      rethrow;
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      AppLogger.info('🔐 Sending password reset email to: $email');
      await client.auth.resetPasswordForEmail(email);
      AppLogger.info('✅ Password reset email sent');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to send password reset email', e, stack);
      rethrow;
    }
  }

  // ---- Profile helpers ----
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      AppLogger.debug('👤 Fetching profile for user: $userId');
      final res = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      
      if (res != null) {
        AppLogger.info('✅ Profile found for user: $userId');
      } else {
        AppLogger.info('⚠️ No profile found for user: $userId');
      }
      
      return res;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch profile for user: $userId', e, stack);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> upsertProfile(Map<String, dynamic> data) async {
    try {
      AppLogger.debug('👤 Upserting profile: ${data['id']}');
      final res = await client
          .from('profiles')
          .upsert(data)
          .select()
          .single();
      AppLogger.info('✅ Profile upserted successfully: ${res['id']}');
      return res;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to upsert profile', e, stack);
      rethrow;
    }
  }

  Future<bool> isProfileComplete(String userId) async {
    try {
      AppLogger.debug('👤 Checking if profile is complete for user: $userId');
      final profile = await getProfile(userId);
      
      if (profile == null) {
        AppLogger.info('⚠️ Profile incomplete: No profile found');
        return false;
      }
      
      final displayName = profile['display_name'];
      final isComplete = displayName != null && displayName.toString().isNotEmpty;
      
      AppLogger.info('✅ Profile complete check: $isComplete');
      return isComplete;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to check profile completeness', e, stack);
      return false;
    }
  }

  // ---- Database helpers ----
  Future<List<Map<String, dynamic>>> getExercises() async {
    try {
      AppLogger.debug('📊 Fetching exercises from database');
      final res = await client.from('exercises').select();
      final exercises = List<Map<String, dynamic>>.from(res);
      AppLogger.info('✅ Fetched ${exercises.length} exercises');
      return exercises;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch exercises', e, stack);
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllWorkouts(String userId) async {
    try {
      AppLogger.debug('📊 Fetching all workouts for user: $userId');
      final res = await client
          .from('workouts')
          .select('*, exercises(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      final workouts = List<Map<String, dynamic>>.from(res);
      AppLogger.info('✅ Fetched ${workouts.length} workouts');
      return workouts;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch all workouts', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  Future<List<Map<String, dynamic>>> getWorkoutsInLastDays(String userId, int days) async {
    try {
      AppLogger.debug('📊 Fetching workouts from last $days days for user: $userId');
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      
      final res = await client
          .from('workouts')
          .select('*, exercises(*)')
          .eq('user_id', userId)
          .gte('created_at', cutoffDate.toIso8601String())
          .order('created_at', ascending: false);
      
      final workouts = List<Map<String, dynamic>>.from(res);
      AppLogger.info('✅ Fetched ${workouts.length} workouts from last $days days');
      return workouts;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch workouts from last $days days', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  Future<List<Map<String, dynamic>>> getAchievements(String userId) async {
    try {
      AppLogger.debug('🏆 Fetching achievements for user: $userId');
      final res = await client
          .from('achievements')
          .select()
          .eq('user_id', userId)
          .order('unlocked_at', ascending: false);
      final achievements = List<Map<String, dynamic>>.from(res);
      AppLogger.info('✅ Fetched ${achievements.length} achievements');
      return achievements;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to fetch achievements', e, stack);
      throw AppException.fromSupabase(e);
    }
  }

  Future<Map<String, dynamic>> insertWorkout(Map<String, dynamic> workout) async {
    try {
      AppLogger.debug('📊 Inserting workout: ${workout['exercise_id']}');
      final res = await client.from('workouts').insert(workout).select().single();
      AppLogger.info('✅ Workout inserted successfully: ${res['id']}');
      return res;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to insert workout', e, stack);
      rethrow;
    }
  }

  // ---- Storage ----
  Future<String> uploadWorkoutVideo(String userId, String path, List<int> bytes) async {
    try {
      final storagePath = 'workouts/$userId/${DateTime.now().millisecondsSinceEpoch}.mp4';
      AppLogger.debug('📤 Uploading workout video: $storagePath');
      
      await client.storage.from('workout-media').uploadBinary(storagePath, bytes as dynamic);
      final url = client.storage.from('workout-media').getPublicUrl(storagePath);
      
      AppLogger.info('✅ Workout video uploaded successfully: $url');
      return url;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to upload workout video for user: $userId', e, stack);
      rethrow;
    }
  }
}