import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';

/// Stream provider that watches Supabase auth state changes
final authStateProvider = StreamProvider<AuthState>((ref) {
  AppLogger.debug('🔐 Auth state provider initialized');
  return SupabaseService.instance.authStateChanges;
});

/// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (state) => state.session?.user,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Guest mode provider
final isGuestProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool('is_guest') ?? false;
});

/// Is authenticated provider (considers both logged in and guest)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  final isGuest = ref.watch(isGuestProvider).value ?? false;
  return user != null || isGuest;
});

/// Profile completeness cache provider
class ProfileCompletenessNotifier extends StateNotifier<AsyncValue<bool>> {
  ProfileCompletenessNotifier(this.ref) : super(const AsyncValue.loading()) {
    _checkCompleteness();
  }

  final Ref ref;
  
  Future<void> _checkCompleteness() async {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data(false);
      return;
    }
    
    try {
      final isComplete = await SupabaseService.instance.isProfileComplete(user.id);
      state = AsyncValue.data(isComplete);
    } catch (e, stack) {
      AppLogger.error('❌ Failed to check profile completeness', e, stack);
      state = AsyncValue.error(e, stack);
    }
  }
  
  /// Force refresh the profile completeness check
  void refresh() {
    _checkCompleteness();
  }
}

final profileCompletenessProvider = StateNotifierProvider<ProfileCompletenessNotifier, AsyncValue<bool>>((ref) {
  return ProfileCompletenessNotifier(ref);
});

/// Set guest mode
Future<void> setGuestMode(bool isGuest) async {
  AppLogger.info('👤 Setting guest mode: $isGuest');
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('is_guest', isGuest);
}

/// Clear guest mode
Future<void> clearGuestMode() async {
  AppLogger.info('👤 Clearing guest mode');
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('is_guest');
}
