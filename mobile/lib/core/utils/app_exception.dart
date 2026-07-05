/// Clean exception wrapper for user-facing error messages
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  AppException({
    required this.message,
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  factory AppException.fromSupabase(dynamic error) {
    if (error is Exception) {
      final errorString = error.toString();
      
      // Parse common Supabase errors
      if (errorString.contains('timeout') || errorString.contains('timed out')) {
        return AppException(
          message: 'Request timed out. Please check your connection and try again.',
          code: 'TIMEOUT',
          originalError: error,
        );
      }
      
      if (errorString.contains('network') || errorString.contains('connection')) {
        return AppException(
          message: 'Network error. Please check your internet connection.',
          code: 'NETWORK',
          originalError: error,
        );
      }
      
      if (errorString.contains('unauthorized') || errorString.contains('401')) {
        return AppException(
          message: 'Session expired. Please sign in again.',
          code: 'UNAUTHORIZED',
          originalError: error,
        );
      }
      
      if (errorString.contains('not found') || errorString.contains('404')) {
        return AppException(
          message: 'Data not found.',
          code: 'NOT_FOUND',
          originalError: error,
        );
      }
    }
    
    // Generic fallback
    return AppException(
      message: 'Something went wrong. Please try again.',
      code: 'UNKNOWN',
      originalError: error,
    );
  }

  factory AppException.network() {
    return AppException(
      message: 'No internet connection. Please check your network.',
      code: 'NETWORK',
    );
  }

  factory AppException.timeout() {
    return AppException(
      message: 'Request timed out. Please try again.',
      code: 'TIMEOUT',
    );
  }

  factory AppException.unauthorized() {
    return AppException(
      message: 'Your session has expired. Please sign in again.',
      code: 'UNAUTHORIZED',
    );
  }
}
