import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/network/dio_client.dart';
import '../../data/repositories/inference_repository.dart';
import '../../data/services/achievement_service.dart';
import '../../data/supabase/supabase_service.dart';
import '../../features/summary/summary_notifier.dart';
import '../../features/summary/summary_state.dart';

/// Barrel file for all app providers
export '../../features/auth/auth_provider.dart';
export '../../features/auth/auth_controller.dart';
export '../../features/home/home_notifier.dart';
export '../../features/profile/profile_setup_controller.dart';
export '../../features/camera/camera_notifier.dart';

// Dio Client (singleton)
final dioClientProvider = Provider<DioClient>((ref) {
  return DioClient();
});

// Inference Repository
final inferenceRepositoryProvider = Provider<InferenceRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return InferenceRepository(dioClient);
});

// Achievement Service
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService();
});

// Summary Provider
final summaryProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  return SummaryNotifier(
    inferenceRepository: ref.watch(inferenceRepositoryProvider),
    achievementService: ref.watch(achievementServiceProvider),
    supabase: SupabaseService.instance,
  );
});
