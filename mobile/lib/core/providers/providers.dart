import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/network/dio_client.dart';
import '../../data/repositories/inference_repository.dart';
import '../../data/repositories/coach_repository.dart';
import '../../data/repositories/progress_repository.dart';
import '../../data/repositories/achievements_repository.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/services/achievement_service.dart';
import '../../data/services/xp_service.dart';
import '../../data/services/daily_challenge_service.dart';
import '../../data/services/gamification_service.dart';
import '../../data/supabase/supabase_service.dart';
import '../../features/summary/summary_notifier.dart';
import '../../features/summary/summary_state.dart';
import '../../features/coach/coach_notifier.dart';
import '../../features/coach/coach_state.dart';
import '../../features/coach/services/coach_context_builder.dart';
import '../../features/coach/services/coach_persistence.dart';
import '../../features/coach/services/voice_input_service.dart';
import '../../features/coach/services/image_picker_service.dart';
import '../../features/achievements/achievements_notifier.dart';
import '../../features/achievements/achievements_state.dart';
import '../../features/profile/profile_notifier.dart';
import '../../features/profile/profile_state.dart';

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

// Coach Repository
final coachRepositoryProvider = Provider<CoachRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return CoachRepository(dio: dioClient);
});

// Progress Repository
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  return ProgressRepository();
});

// Coach Context Builder
final coachContextBuilderProvider = Provider<CoachContextBuilder>((ref) {
  return CoachContextBuilder(
    progressRepo: ref.watch(progressRepositoryProvider),
  );
});

// Coach Persistence
final coachPersistenceProvider = Provider<CoachPersistence>((ref) {
  final persistence = CoachPersistence();
  persistence.init();
  return persistence;
});

// Voice Input Service
final voiceInputServiceProvider = Provider<VoiceInputService>((ref) {
  return VoiceInputService();
});

// Image Picker Service
final imagePickerServiceProvider = Provider<ImagePickerService>((ref) {
  return ImagePickerService();
});

// XP Service
final xpServiceProvider = Provider<XpService>((ref) {
  return XpService();
});

// Daily Challenge Service
final dailyChallengeServiceProvider = Provider<DailyChallengeService>((ref) {
  return DailyChallengeService();
});

// Achievement Service
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return AchievementService(
    xpService: ref.watch(xpServiceProvider),
  );
});

// Gamification Service
final gamificationServiceProvider = Provider<GamificationService>((ref) {
  return GamificationService(
    xpService: ref.watch(xpServiceProvider),
    achievementService: ref.watch(achievementServiceProvider),
    challengeService: ref.watch(dailyChallengeServiceProvider),
  );
});

// Achievements Repository
final achievementsRepositoryProvider = Provider<AchievementsRepository>((ref) {
  return AchievementsRepository(
    challengeService: ref.watch(dailyChallengeServiceProvider),
  );
});

// Summary Provider
final summaryProvider = StateNotifierProvider<SummaryNotifier, SummaryState>((ref) {
  return SummaryNotifier(
    inferenceRepository: ref.watch(inferenceRepositoryProvider),
    gamificationService: ref.watch(gamificationServiceProvider),
    supabase: SupabaseService.instance,
  );
});

// Achievements Provider (with userId parameter)
final achievementsNotifierProvider = StateNotifierProvider.family<AchievementsNotifier, AchievementsState, String>((ref, userId) {
  return AchievementsNotifier(
    repository: ref.watch(achievementsRepositoryProvider),
    userId: userId,
  );
});

// Profile Repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

// Profile Provider (with userId parameter)
final profileNotifierProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, userId) {
  return ProfileNotifier(
    repository: ref.watch(profileRepositoryProvider),
    userId: userId,
    imagePickerService: ref.watch(imagePickerServiceProvider),
  );
});

// Coach Provider
final coachProvider = StateNotifierProvider<CoachNotifier, CoachState>((ref) {
  return CoachNotifier(
    repository: ref.watch(coachRepositoryProvider),
    contextBuilder: ref.watch(coachContextBuilderProvider),
    persistence: ref.watch(coachPersistenceProvider),
    voiceService: ref.watch(voiceInputServiceProvider),
    imageService: ref.watch(imagePickerServiceProvider),
    ref: ref,
  );
});
