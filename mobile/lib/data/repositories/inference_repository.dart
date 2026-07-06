import 'package:dio/dio.dart';
import '../../core/exceptions/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/inference_models.dart';
import '../network/dio_client.dart';

/// Repository for inference and coach service calls
class InferenceRepository {
  final DioClient _dio;

  InferenceRepository(this._dio);

  /// Analyze pre-computed angles from camera session
  Future<InferenceResult> analyzeAngles({
    required String exerciseId,
    required List<Map<String, double>> framesAngles,
    required int durationSeconds,
    required int totalRepsMobile,
    required List<bool> repQualityMobile,
  }) async {
    try {
      AppLogger.info(
        '🧠 Analyzing angles: exercise=$exerciseId, '
        'frames=${framesAngles.length}, '
        'reps=$totalRepsMobile',
      );

      final response = await _dio.inference.post(
        '/inference/analyze-angles',
        data: {
          'exercise': exerciseId,
          'frames_angles': framesAngles,
          'duration_seconds': durationSeconds,
          'total_reps_mobile': totalRepsMobile,
          'rep_quality_mobile': repQualityMobile,
        },
      );

      final result = InferenceResult.fromJson(response.data as Map<String, dynamic>);
      AppLogger.info('✅ Analysis complete: avg score=${result.avgScore}');
      return result;
    } on DioException catch (e) {
      AppLogger.error('❌ Failed to analyze angles', e);

      if (e.response?.statusCode == 422) {
        throw AppException('Exercise not recognized by AI service');
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AppException(
          'Analysis timed out — your workout will be saved with basic stats',
        );
      }

      if (e.type == DioExceptionType.connectionError) {
        throw AppException(
          'Cannot reach AI service — your workout will be saved with basic stats',
        );
      }

      throw AppException(
        'AI analysis failed — your workout will be saved with basic stats',
      );
    } catch (e, stack) {
      AppLogger.error('❌ Unexpected error in analyzeAngles', e, stack);
      throw AppException(
        'AI analysis failed — your workout will be saved with basic stats',
      );
    }
  }

  /// Get natural language workout summary from LLM coach
  Future<String> getWorkoutSummary({
    required String exerciseId,
    required String coachingSummary,
    required int totalReps,
    required double avgScore,
  }) async {
    try {
      AppLogger.info('💬 Getting workout summary from LLM coach');

      final response = await _dio.coach.post(
        '/coach/workout-summary',
        data: {
          'exercise': exerciseId,
          'coaching_summary': coachingSummary,
          'total_reps': totalReps,
          'avg_score': avgScore,
        },
      );

      final summary = response.data['summary'] as String? ?? '';
      AppLogger.info('✅ LLM summary received');
      return summary;
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to get LLM summary, using fallback', e, stack);
      
      // Return fallback - never throw
      return 'Good session with $totalReps reps. Average form score: ${avgScore.toStringAsFixed(1)}/100.';
    }
  }

  /// Get natural language explanation for a form issue
  Future<String> getRepFeedback(FormIssue issue) async {
    try {
      AppLogger.debug('💬 Getting rep feedback from LLM coach');

      final response = await _dio.coach.post(
        '/coach/rep-feedback',
        data: {
          'problem': issue.problem,
          'reason': issue.reason,
          'correction': issue.correction,
          'confidence': issue.confidence,
          'severity': issue.severity,
        },
      );

      return response.data['feedback'] as String? ?? issue.correction;
    } catch (e, stack) {
      AppLogger.warning('⚠️ Failed to get rep feedback, using fallback', e, stack);
      
      // Return raw correction as fallback
      return issue.correction;
    }
  }

  /// Check if inference service is available
  Future<bool> isInferenceServiceAvailable() async {
    try {
      final response = await _dio.inference.get(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      
      final isAvailable = response.statusCode == 200;
      AppLogger.info(
        isAvailable
            ? '✅ Inference service available'
            : '⚠️ Inference service unavailable',
      );
      return isAvailable;
    } catch (e) {
      AppLogger.warning('⚠️ Inference service unavailable', e);
      return false;
    }
  }

  /// Check if coach service is available
  Future<bool> isCoachServiceAvailable() async {
    try {
      final response = await _dio.coach.get(
        '/health',
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      
      final isAvailable = response.statusCode == 200;
      AppLogger.info(
        isAvailable
            ? '✅ Coach service available'
            : '⚠️ Coach service unavailable',
      );
      return isAvailable;
    } catch (e) {
      AppLogger.warning('⚠️ Coach service unavailable', e);
      return false;
    }
  }
}
