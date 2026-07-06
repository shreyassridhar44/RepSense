import '../../core/exceptions/app_exception.dart';
import '../../core/network/dio_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/chat_models.dart';
import 'package:dio/dio.dart';

/// Repository for AI coach interactions
class CoachRepository {
  final DioClient _dio;

  CoachRepository({DioClient? dio}) : _dio = dio ?? DioClient();

  /// Ask the AI coach a question with conversation history and context
  Future<({String answer, List<String> followups})> ask({
    required String question,
    required List<ChatMessage> conversationHistory,
    required CoachContext? context,
  }) async {
    try {
      AppLogger.info('🤖 Asking coach: $question');

      // Convert conversation history to API format (last 20 messages only)
      final historyToSend = conversationHistory.length > 20
          ? conversationHistory.sublist(conversationHistory.length - 20)
          : conversationHistory;

      final history = historyToSend
          .map((msg) => {
                'role': msg.role == MessageRole.user ? 'user' : 'assistant',
                'content': msg.content,
              })
          .toList();

      final response = await _dio.coach.post(
        '/ask',
        data: {
          'question': question,
          'conversation_history': history,
          'user_context': context?.toJson(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final answer = response.data['answer'] as String;
      final followups = (response.data['suggested_followups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      AppLogger.info('✅ Coach responded with ${answer.length} chars');
      return (answer: answer, followups: followups);
    } on DioException catch (e) {
      AppLogger.error('❌ Coach ask failed', e);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AppException(
          'The coach is taking too long — try a simpler question',
        );
      }

      if (e.response?.statusCode == 503) {
        throw AppException(
          'Coach service is unavailable — try again in a moment',
        );
      }

      throw AppException(
        'Couldn\'t reach your AI coach — check your connection',
      );
    } catch (e, stack) {
      AppLogger.error('❌ Unexpected coach error', e, stack);
      throw AppException(
        'Couldn\'t reach your AI coach — check your connection',
      );
    }
  }

  /// Analyze an image with the AI coach
  Future<({String answer, List<String> followups})> analyzeImage({
    required String imageBase64,
    required String mediaType,
    required String question,
    required CoachContext? context,
  }) async {
    try {
      // Check image size (5MB limit)
      final sizeInMB = (imageBase64.length * 0.75) / (1024 * 1024); // base64 overhead
      if (sizeInMB > 5) {
        throw AppException('Image is too large — try a smaller screenshot');
      }

      AppLogger.info('🖼️ Analyzing image with coach');

      final response = await _dio.coach.post(
        '/analyze-image',
        data: {
          'image_base64': imageBase64,
          'media_type': mediaType,
          'question': question,
          'user_context': context?.toJson(),
        },
        options: Options(
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final answer = response.data['answer'] as String;
      final followups = (response.data['suggested_followups'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      AppLogger.info('✅ Image analysis complete');
      return (answer: answer, followups: followups);
    } on DioException catch (e) {
      AppLogger.error('❌ Image analysis failed', e);

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw AppException(
          'The coach is taking too long — try a simpler question',
        );
      }

      if (e.response?.statusCode == 503) {
        throw AppException(
          'Coach service is unavailable — try again in a moment',
        );
      }

      throw AppException(
        'Couldn\'t reach your AI coach — check your connection',
      );
    } catch (e, stack) {
      AppLogger.error('❌ Unexpected image analysis error', e, stack);
      throw AppException(
        'Couldn\'t reach your AI coach — check your connection',
      );
    }
  }

  /// Check if coach service is available
  Future<bool> isAvailable() async {
    try {
      await _dio.coach.get(
        '/health',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
      return true;
    } catch (e) {
      AppLogger.debug('Coach service unavailable');
      return false;
    }
  }

  /// Clear context (no-op on server, used for logging)
  Future<void> clearContext() async {
    try {
      await _dio.coach.post('/clear-context');
    } catch (e) {
      // Non-critical, ignore
      AppLogger.debug('Clear context call failed (non-critical)');
    }
  }
}
