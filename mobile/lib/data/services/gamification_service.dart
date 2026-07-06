import '../../core/utils/app_logger.dart';
import '../models/inference_models.dart';
import 'achievement_service.dart';
import 'daily_challenge_service.dart';
import 'xp_service.dart';

/// Result of gamification processing
class GamificationResult {
  final XpResult xpResult;
  final List<String> newBadges;
  final bool dailyChallengeCompleted;
  final bool levelledUp;

  const GamificationResult({
    required this.xpResult,
    required this.newBadges,
    required this.dailyChallengeCompleted,
    required this.levelledUp,
  });

  bool get hasRewards =>
      xpResult.xpAwarded > 0 ||
      newBadges.isNotEmpty ||
      dailyChallengeCompleted ||
      levelledUp;
}

/// Orchestrator service for all gamification features
class GamificationService {
  final XpService _xpService;
  final AchievementService _achievementService;
  final DailyChallengeService _challengeService;

  GamificationService({
    XpService? xpService,
    AchievementService? achievementService,
    DailyChallengeService? challengeService,
  })  : _xpService = xpService ?? XpService(),
        _achievementService = achievementService ?? AchievementService(),
        _challengeService = challengeService ?? DailyChallengeService();

  /// Process gamification after workout completion
  Future<GamificationResult> processWorkout({
    required String userId,
    required Map<String, dynamic> workoutData,
    required List<Map<String, dynamic>> allWorkouts,
    required InferenceResult? inferenceResult,
  }) async {
    try {
      AppLogger.info('🎮 Processing gamification for workout');

      // Calculate XP to award
      int totalXp = _calculateWorkoutXp(workoutData, inferenceResult);

      // Award XP
      final xpResult = await _xpService.awardXp(
        userId: userId,
        amount: totalXp,
        reason: 'Workout completed',
      );

      // Update daily challenge
      final updatedChallenge = await _challengeService.updateProgress(
        userId: userId,
        workoutData: workoutData,
      );

      final challengeCompleted = updatedChallenge?.isCompleted == true &&
          updatedChallenge?.completedAt?.day == DateTime.now().day;

      // Award challenge completion XP
      if (challengeCompleted && updatedChallenge != null) {
        await _xpService.awardXp(
          userId: userId,
          amount: updatedChallenge.xpReward,
          reason: 'Daily challenge completed',
        );
      }

      // Check achievements
      final newBadges = await _achievementService.checkAndUnlock(
        userId: userId,
        allWorkouts: allWorkouts,
        inferenceResult: inferenceResult,
      );

      final result = GamificationResult(
        xpResult: xpResult,
        newBadges: newBadges,
        dailyChallengeCompleted: challengeCompleted,
        levelledUp: xpResult.levelledUp,
      );

      AppLogger.info('✅ Gamification processed: ${result.hasRewards ? "rewards earned" : "no rewards"}');
      return result;
    } catch (e, stack) {
      AppLogger.error('❌ Failed to process gamification', e, stack);
      // Return empty result on error
      return GamificationResult(
        xpResult: XpResult(
          xpAwarded: 0,
          newTotalXp: 0,
          previousLevel: 1,
          newLevel: 1,
          levelledUp: false,
          xpToNextLevel: 200,
          progressToNextLevel: 0.0,
        ),
        newBadges: const [],
        dailyChallengeCompleted: false,
        levelledUp: false,
      );
    }
  }

  /// Calculate XP for a workout
  int _calculateWorkoutXp(
    Map<String, dynamic> workoutData,
    InferenceResult? inferenceResult,
  ) {
    int xp = XpRewards.workoutCompleted;

    // Perfect form reps
    if (inferenceResult != null) {
      final perfectReps = inferenceResult.reps.where((r) => r.overallScore >= 95).length;
      final goodReps = inferenceResult.reps.where((r) => r.overallScore >= 70 && r.overallScore < 95).length;

      xp += perfectReps * XpRewards.perfectFormRep;
      xp += goodReps * XpRewards.goodFormRep;
    }

    // First workout of day bonus
    final isFirstToday = workoutData['is_first_today'] as bool? ?? false;
    if (isFirstToday) {
      xp += XpRewards.firstWorkoutOfDay;
    }

    AppLogger.debug('💎 Calculated $xp XP for workout');
    return xp;
  }
}
