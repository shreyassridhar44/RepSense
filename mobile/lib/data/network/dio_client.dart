import 'package:dio/dio.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/app_logger.dart';
import '../../data/supabase/supabase_service.dart';

/// Configured Dio clients for inference and coach services
class DioClient {
  late final Dio _inference;
  late final Dio _coach;

  DioClient() {
    _inference = Dio(BaseOptions(
      baseUrl: AppConfig.inferenceServiceUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30), // inference can be slow
      sendTimeout: const Duration(seconds: 15), // sending angle sequence
      headers: {'Content-Type': 'application/json'},
    ));

    _coach = Dio(BaseOptions(
      baseUrl: AppConfig.coachServiceUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30), // LLM can be slow
      sendTimeout: const Duration(seconds: 5),
      headers: {'Content-Type': 'application/json'},
    ));

    // Add interceptors to both
    _addInterceptors(_inference, 'InferenceService');
    _addInterceptors(_coach, 'CoachService');
  }

  void _addInterceptors(Dio dio, String serviceName) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        // Attach Supabase JWT to every request
        final token = SupabaseService.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        
        AppLogger.debug('🌐 $serviceName request: ${options.method} ${options.path}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.debug('✅ $serviceName response: ${response.statusCode}');
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error(
          '❌ $serviceName error: ${error.response?.statusCode ?? 'No status'}',
          error,
        );
        handler.next(error);
      },
    ));

    // Retry interceptor: retry once on connection timeout or 503
    dio.interceptors.add(RetryInterceptor(dio: dio));
  }

  Dio get inference => _inference;
  Dio get coach => _coach;
}

/// Retry interceptor for handling transient network failures
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration retryDelay;
  final Set<int> retryableStatuses;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 1,
    this.retryDelay = const Duration(seconds: 2),
    this.retryableStatuses = const {503},
  });

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Check if request has retry count
    final extra = err.requestOptions.extra;
    final retryCount = extra['retryCount'] as int? ?? 0;

    // Don't retry if max retries reached
    if (retryCount >= maxRetries) {
      AppLogger.debug('⚠️ Max retries reached for ${err.requestOptions.path}');
      return handler.next(err);
    }

    // Only retry on specific conditions
    final shouldRetry = _shouldRetry(err);
    if (!shouldRetry) {
      return handler.next(err);
    }

    // Increment retry count
    extra['retryCount'] = retryCount + 1;

    AppLogger.info(
      '🔄 Retrying request (attempt ${retryCount + 1}/$maxRetries): ${err.requestOptions.path}',
    );

    // Wait before retrying
    await Future.delayed(retryDelay);

    // Retry the request
    try {
      final response = await dio.fetch(err.requestOptions);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  bool _shouldRetry(DioException err) {
    // Retry on connection timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      return true;
    }

    // Retry on specific status codes
    final statusCode = err.response?.statusCode;
    if (statusCode != null && retryableStatuses.contains(statusCode)) {
      return true;
    }

    return false;
  }
}
