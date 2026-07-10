import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:repsense/core/utils/app_exception.dart';
import 'package:repsense/core/utils/app_logger.dart';
import 'package:repsense/core/utils/angle_utils.dart';
import 'package:repsense/data/models/inference_models.dart';
import 'package:repsense/data/repositories/inference_repository.dart';
import 'package:repsense/data/services/gamification_service.dart';
import 'package:repsense/data/supabase/supabase_service.dart';
import 'summary_state.dart';

/// Summary notifier - orchestrates inference, save, and gamification
class SummaryNotifier extends StateNotifier<SummaryState> {
  final InferenceRepository _inferenceRepository;
  final GamificationService _gamificationService;
  final SupabaseService _supabase;

  SummaryNotifier({
    required InferenceRepository inferenceRepository,
    required GamificationService gamificationService,
    required SupabaseService supabase,
  })  : _inferenceRepository = inferenceRepository,
        _gamificationService = gamificationService,
        _supabase = supabase,
        super(SummaryState(sessionStartTime: DateTime.now()));

  /// Initialize with camera result data
  Future<void> initialize(Map<String, dynamic> cameraResult) async {
    try {
      AppLogger.info('📊 Initializing summary with camera result');

      // Parse camera result immediately
      final exerciseId = cameraResult['exerciseId'] as String? ?? '';
      final exerciseName = cameraResult['exerciseName'] as String? ?? '';
      final totalReps = cameraResult['reps'] as int? ?? 0;
      final correctReps = cameraResult['correctReps'] as int? ?? 0;
      final incorrectReps = cameraResult['incorrectReps'] as int? ?? 0;
      final repQuality = (cameraResult['repQuality'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          [];
      final durationSeconds = cameraResult['durationSeconds'] as int? ?? 0;
      final estimatedCalories = (cameraResult['estimatedCalories'] as num?)?.toDouble() ?? 0.0;
      final sessionStartTime = cameraResult['sessionStartTime'] != null
          ? DateTime.parse(cameraResult['sessionStartTime'] as String)
          : DateTime.now();
      final angleSequence = (cameraResult['angleSequence'] as List<dynamic>?)
              ?.map((e) => Map<String, double>.from(e as Map))
              .toList() ??
          [];

      // Update state with parsed data immediately
      state = state.copyWith(
        status: SummaryStatus.analyzing,
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        totalReps: totalReps,
        correctReps: correctReps,
        incorrectReps: incorrectReps,
        repQuality: repQuality,
        durationSeconds: durationSeconds,
        estimatedCalories: estimatedCalories,
        sessionStartTime: sessionStartTime,
        angleSequence: angleSequence,
      );

      // Handle empty reps case
      if (totalReps == 0 || angleSequence.isEmpty) {
        AppLogger.warning('⚠️ No reps recorded, skipping inference');
        
        // Save basic workout anyway
        await _saveBasicWorkout();
        
        state = state.copyWith(
          status: SummaryStatus.complete,
          workoutSummaryText: 'No reps recorded — start a new session to track your form.',
        );
        return;
      }

      // Run inference and save concurrently
      await Future.wait([
        _runInference(),
        _saveBasicWorkout(),
      ]);
    } catch (e, stack) {
      AppLogger.error('❌ Failed to initialize summary', e, stack);
      state = state.copyWith(
        status: SummaryStatus.complete,
        inferenceErrorMessage: 'Failed to initialize summary',
      );
    }
  }

  /// Run AI inference on angle sequence
  Future<void> _runInference() async {
    try {
      AppLogger.info('🧠 Running AI inference');

      // Subsample angles if needed
      final subsampledAngles = AngleUtils.subsampleAngles(
        state.angleSequence,
        maxFrames: 1500,
      );

      // Estimate payload size
      final payloadSizeKB = AngleUtils.estimatePayloadSizeKB(subsampledAngles);
      AppLogger.debug('📦 Payload size: ${payloadSizeKB}KB');

      // Call inference service
      final result = await _inferenceRepository.analyzeAngles(
        exerciseId: state.exerciseId,
        framesAngles: subsampledAngles,
        durationSeconds: state.durationSeconds,
        totalRepsMobile: state.totalReps,
        repQualityMobile: state.repQuality,
      );

      state = state.copyWith(inferenceResult: result);

      // Get workout summary and update scores concurrently
      await Future.wait([
        _getWorkoutSummary(),
        if (state.savedWorkoutId != null)
          _updateWorkoutWithScores(state.savedWorkoutId!, result),
      ]);

      state = state.copyWith(status: SummaryStatus.complete);
      AppLogger.info('✅ Inference complete');
    } on AppException catch (e) {
      AppLogger.error('❌ Inference failed', e);
      state = state.copyWith(
        inferenceErrorMessage: e.message,
        inferenceFailedButSaved: true,
        status: SummaryStatus.complete,
      );
    } catch (e, stack) {
      AppLogger.error('❌ Unexpected inference error', e, stack);
      state = state.copyWith(
        inferenceErrorMessage: 'AI analysis failed unexpectedly',
        inferenceFailedButSaved: true,
        status: SummaryStatus.complete,
      );
    }
  }

  /// Save basic workout to Supabase
  Future<void> _saveBasicWorkout() async {
    try {
      AppLogger.info('💾 Saving basic workout to Supabase');

      final user = _supabase.currentUser;
      if (user == null) {
        throw AppException(message: 'User not authenticated');
      }

      final basicScore = state.displayScore;

      final response = await _supabase.client.from('workouts').insert({
        'user_id': user.id,
        'exercise_id': state.exerciseId,
        'total_reps': state.totalReps,
        'correct_reps': state.correctReps,
        'incorrect_reps': state.incorrectReps,
        'avg_form_score': basicScore,
        'duration_seconds': state.durationSeconds,
        'calories': state.estimatedCalories,
        'created_at': state.sessionStartTime.toIso8601String(),
      }).select('id').single();

      final workoutId = response['id'] as String;

      state = state.copyWith(
        savedWorkoutId: workoutId,
        isSaved: true,
      );

      AppLogger.info('✅ Workout saved: $workoutId');

      // Process gamification (XP, challenges, achievements)
      await _processGamification(user.id, workoutId);
    } catch (e, stack) {
      AppLogger.error('❌ Failed to save workout', e, stack);
      state = state.copyWith(
        saveErrorMessage: 'Failed to save workout: ${e.toString()}',
      );
    }
  }

  /// Update workout with inference scores
  Future<void> _updateWorkoutWithScores(
    String workoutId,
    InferenceResult result,
  ) async {
    try {
      AppLogger.info('📊 Updating workout with inference scores');

      // Update workout row
      await _supabase.client.from('workouts').update({
        'avg_form_score': result.avgScore,
      }).eq('id', workoutId);

      // Insert rep analyses
      if (result.reps.isNotEmpty) {
        final repRows = result.reps.map((rep) => {
              'workout_id': workoutId,
              'rep_index': rep.repIndex,
              'overall_score': rep.overallScore,
              'scores': rep.scores.toJson(),
              'issues': rep.issues.map((i) => i.toJson()).toList(),
            }).toList();

        try {
          await _supabase.client.from('rep_analyses').insert(repRows);
          AppLogger.info('✅ Rep analyses saved');
        } catch (e, stack) {
          AppLogger.warning('⚠️ Failed to save rep analyses (non-critical)', e, stack);
          // Retry once
          try {
            await _supabase.client.from('rep_analyses').insert(repRows);
            AppLogger.info('✅ Rep analyses saved on retry');
          } catch (e2) {
            AppLogger.error('❌ Rep analyses save failed on retry', e2);
            // Non-critical, continue
          }
        }
      }

      AppLogger.info('✅ Workout updated with scores');
    } catch (e, stack) {
      AppLogger.error('❌ Failed to update workout with scores', e, stack);
      // Non-critical, don't block UI
    }
  }

  /// Get LLM-generated workout summary
  Future<void> _getWorkoutSummary() async {
    if (state.inferenceResult == null) return;

    try {
      AppLogger.info('💬 Getting LLM workout summary');

      final summary = await _inferenceRepository.getWorkoutSummary(
        exerciseId: state.exerciseId,
        coachingSummary: state.inferenceResult!.coachingSummary,
        totalReps: state.totalReps,
        avgScore: state.inferenceResult!.avgScore,
      );

      state = state.copyWith(workoutSummaryText: summary);
      AppLogger.info('✅ LLM summary received');
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to get LLM summary', e, stack);
      // Fallback is already handled in repository
    }
  }

  /// Process gamification (XP, challenges, achievements)
  Future<void> _processGamification(String userId, String workoutId) async {
    try {
      AppLogger.info('🎮 Processing gamification');

      // Fetch workout data
      final workoutData = await _supabase.client
          .from('workouts')
          .select('*')
          .eq('id', workoutId)
          .single();

      // Fetch all user workouts
      final allWorkouts = await _supabase.client
          .from('workouts')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      // Check if first workout today
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final isFirstToday = (allWorkouts as List).where((w) {
        final created = DateTime.parse(w['created_at'] as String);
        return created.isAfter(todayStart);
      }).length == 1;

      workoutData['is_first_today'] = isFirstToday;

      // Process gamification
      final result = await _gamificationService.processWorkout(
        userId: userId,
        workoutData: workoutData,
        allWorkouts: List<Map<String, dynamic>>.from(allWorkouts),
        inferenceResult: state.inferenceResult,
      );

      if (result.newBadges.isNotEmpty) {
        state = state.copyWith(newlyUnlockedAchievements: result.newBadges);
        AppLogger.info('🎉 Unlocked ${result.newBadges.length} badges');
      }

      if (result.xpResult.xpAwarded > 0) {
        AppLogger.info('⭐ Earned ${result.xpResult.xpAwarded} XP');
      }
    } catch (e, stack) {
      AppLogger.error('❌ Failed to process gamification', e, stack);
      // Non-critical, continue
    }
  }

  /// Retry saving workout
  Future<void> retrySave() async {
    if (state.isSaved) return;

    AppLogger.info('🔄 Retrying workout save');
    state = state.copyWith(
      saveErrorMessage: null,
      status: SummaryStatus.savingToCloud,
    );

    await _saveBasicWorkout();

    // If inference succeeded, update with scores
    if (state.inferenceResult != null && state.savedWorkoutId != null) {
      await _updateWorkoutWithScores(
        state.savedWorkoutId!,
        state.inferenceResult!,
      );
    }

    state = state.copyWith(status: SummaryStatus.complete);
  }

  /// Retry AI inference
  Future<void> retryInference() async {
    if (state.inferenceResult != null) return;

    AppLogger.info('🔄 Retrying AI inference');
    state = state.copyWith(
      inferenceErrorMessage: null,
      inferenceFailedButSaved: false,
      status: SummaryStatus.analyzing,
    );

    await _runInference();
  }
}
