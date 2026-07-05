import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/auth_provider.dart';
import '../utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';
import '../../features/splash/splash_page.dart';
import '../../features/onboarding/onboarding_page.dart';
import '../../features/auth/auth_page.dart';
import '../../features/profile/profile_setup_page.dart';
import '../../features/home/home_shell.dart';
import '../../features/workout/workout_selection_page.dart';
import '../../features/workout/exercise_detail_page.dart';
import '../../features/workout/workout_history_page.dart';
import '../../features/camera/camera_page.dart';
import '../../features/summary/summary_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Watch auth state so router rebuilds when auth changes
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshNotifier(ref),
    redirect: (context, state) async {
      final loc = state.matchedLocation;
      
      // Check if user is authenticated
      final user = SupabaseService.instance.currentUser;
      final loggedIn = user != null;
      
      // Check if guest mode
      final isGuestAsync = ref.read(isGuestProvider);
      final isGuest = isGuestAsync.value ?? false;
      
      AppLogger.debug('🧭 Router redirect: location=$loc, loggedIn=$loggedIn, isGuest=$isGuest');

      // Allow splash and onboarding
      if (loc == '/splash' || loc == '/onboarding') {
        return null;
      }

      // Not authenticated and not guest → redirect to auth
      if (!loggedIn && !isGuest && loc != '/auth') {
        AppLogger.info('🔒 Redirecting to /auth (not authenticated)');
        return '/auth';
      }

      // Authenticated → check profile completeness
      if (loggedIn && loc != '/profile-setup') {
        try {
          final isComplete = await SupabaseService.instance.isProfileComplete(user.id);
          
          if (!isComplete && loc != '/profile-setup') {
            AppLogger.info('� Redirecting to /profile-setup (profile incomplete)');
            return '/profile-setup';
          }
          
          // Profile complete and trying to access auth → go home
          if (isComplete && loc == '/auth') {
            AppLogger.info('✅ Redirecting to /home (already authenticated with complete profile)');
            return '/home';
          }
        } catch (e) {
          AppLogger.error('❌ Error checking profile completeness', e);
          // On error, allow navigation
        }
      }

      // Guest trying to access auth or splash → go home
      if (isGuest && (loc == '/auth' || loc == '/splash')) {
        AppLogger.info('✅ Redirecting to /home (guest mode)');
        return '/home';
      }

      AppLogger.debug('✅ No redirect needed');
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /splash');
          return const SplashPage();
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /onboarding');
          return const OnboardingPage();
        },
      ),
      GoRoute(
        path: '/auth',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /auth');
          return const AuthPage();
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /profile-setup');
          return const ProfileSetupPage();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /home');
          return const HomeShell();
        },
      ),
      GoRoute(
        path: '/workouts',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /workouts');
          return const WorkoutSelectionPage();
        },
      ),
      GoRoute(
        path: '/workout-history',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /workout-history');
          return const WorkoutHistoryPage();
        },
      ),
      GoRoute(
        path: '/exercise/:id',
        builder: (c, s) {
          final id = s.pathParameters['id']!;
          AppLogger.debug('📱 Navigating to: /exercise/$id');
          return ExerciseDetailPage(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/camera/:exerciseId',
        builder: (c, s) {
          final id = s.pathParameters['exerciseId']!;
          AppLogger.debug('📱 Navigating to: /camera/$id');
          return CameraPage(exerciseId: id);
        },
      ),
      GoRoute(
        path: '/summary',
        builder: (c, s) {
          AppLogger.debug('📱 Navigating to: /summary');
          return SummaryPage(result: s.extra as Map<String, dynamic>? ?? const {});
        },
      ),
    ],
  );
});

/// Helper class to make GoRouter reactive to Riverpod state changes  
class GoRouterRefreshNotifier with ChangeNotifier {
  GoRouterRefreshNotifier(Ref ref) {
    // Watch auth state and notify listeners on changes
    ref.listen(
      authStateProvider,
      (_, __) {
        notifyListeners();
      },
    );
  }
}
