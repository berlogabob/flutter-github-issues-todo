import '../utils/logging.dart';

/// Result type for error handling
class Result<T> {
  final T? data;
  final String? error;
  final bool isSuccess;

  Result._({this.data, this.error, required this.isSuccess});

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(String error) =>
      Result._(error: error, isSuccess: false);

  /// Map the success value
  Result<R> map<R>(R Function(T value) mapper) {
    if (!isSuccess) return Result<R>._(error: error, isSuccess: false);
    return Result<R>._(data: mapper(data as T), isSuccess: true);
  }

  /// Chain async operations
  Future<Result<R>> asyncMap<R>(Future<R> Function(T value) mapper) async {
    if (!isSuccess) return Result<R>._(error: error, isSuccess: false);
    try {
      final result = await mapper(data as T);
      return Result.success(result);
    } catch (e, stackTrace) {
      Logger.e(
        'Async map failed',
        error: e,
        stackTrace: stackTrace,
        context: 'Result',
      );
      return Result.failure(e.toString());
    }
  }

  /// Get the data or throw
  T get requireData {
    if (!isSuccess) throw Exception(error);
    return data as T;
  }

  /// Get the error or throw
  String get requireError {
    if (isSuccess) throw Exception('Result is successful');
    return error ?? 'Unknown error';
  }

  @override
  String toString() {
    return isSuccess ? 'Result.success($data)' : 'Result.failure($error)';
  }
}

/// Standard error codes for GitHub API operations
enum GitHubErrorCode {
  unauthorized,
  forbidden,
  notFound,
  rateLimitExceeded,
  networkError,
  serverError,
  unknown,
}

/// GitHub API Error with standardized handling
class GitHubApiError implements Exception {
  final String message;
  final GitHubErrorCode code;
  final int? statusCode;
  final String? endpoint;

  GitHubApiError({
    required this.message,
    required this.code,
    this.statusCode,
    this.endpoint,
  });

  /// Create from HTTP status code
  factory GitHubApiError.fromStatusCode(int statusCode, String endpoint) {
    switch (statusCode) {
      case 401:
        return GitHubApiError(
          message: 'Invalid authentication token',
          code: GitHubErrorCode.unauthorized,
          statusCode: statusCode,
          endpoint: endpoint,
        );
      case 403:
        return GitHubApiError(
          message: 'Access forbidden. Check repository permissions',
          code: GitHubErrorCode.forbidden,
          statusCode: statusCode,
          endpoint: endpoint,
        );
      case 404:
        return GitHubApiError(
          message: 'Resource not found',
          code: GitHubErrorCode.notFound,
          statusCode: statusCode,
          endpoint: endpoint,
        );
      case 429:
        return GitHubApiError(
          message: 'Rate limit exceeded. Please wait before retrying',
          code: GitHubErrorCode.rateLimitExceeded,
          statusCode: statusCode,
          endpoint: endpoint,
        );
      default:
        if (statusCode >= 500) {
          return GitHubApiError(
            message: 'GitHub server error. Please try again later',
            code: GitHubErrorCode.serverError,
            statusCode: statusCode,
            endpoint: endpoint,
          );
        }
        return GitHubApiError(
          message: 'Unexpected error: $statusCode',
          code: GitHubErrorCode.unknown,
          statusCode: statusCode,
          endpoint: endpoint,
        );
    }
  }

  /// Create from network error
  factory GitHubApiError.network(String endpoint) {
    return GitHubApiError(
      message: 'Network error. Please check your internet connection',
      code: GitHubErrorCode.networkError,
      endpoint: endpoint,
    );
  }

  @override
  String toString() => 'GitHubApiError(${code.name}): $message';
}

/// Error handler for standard error scenarios
class ErrorHandler {
  /// Handle error and return user-friendly message
  static String handleErrorMessage(Object error) {
    if (error is GitHubApiError) {
      return error.message;
    }
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An unexpected error occurred';
  }

  /// Log error with standard context
  static void logError(
    String operation,
    String context, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    Logger.e(
      'Operation failed: $operation',
      error: error,
      stackTrace: stackTrace,
      context: context,
      metadata: metadata,
    );
  }

  /// Check if error is recoverable
  static bool isRecoverableError(Object error) {
    if (error is GitHubApiError) {
      return error.code == GitHubErrorCode.networkError ||
          error.code == GitHubErrorCode.serverError;
    }
    return false;
  }

  /// Get retry delay based on error type
  static Duration getRetryDelay(Object error) {
    if (error is GitHubApiError) {
      switch (error.code) {
        case GitHubErrorCode.rateLimitExceeded:
          return const Duration(minutes: 5);
        case GitHubErrorCode.networkError:
        case GitHubErrorCode.serverError:
          return const Duration(seconds: 5);
        default:
          return const Duration(seconds: 10);
      }
    }
    return const Duration(seconds: 10);
  }
}

/// Retry configuration for operations
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final Set<Type> retryableExceptions;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 1),
    this.retryableExceptions = const {
      GitHubApiError,
      // Add other retryable exception types here
    },
  });

  /// Default config for GitHub API calls
  static const githubApi = RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(seconds: 2),
    backoffMultiplier: 2.0,
    maxDelay: Duration(minutes: 1),
  );

  /// Default config for local operations
  static const local = RetryConfig(
    maxRetries: 2,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 5),
  );
}

/// Execute operation with retry logic
///
/// Usage:
/// ```dart
/// final result = await retryOperation(
///   () => githubService.fetchIssues(),
///   config: RetryConfig.githubApi,
///   onRetry: (attempt, error) {
///     Logger.w('Retry attempt $attempt after error: $error', context: 'GitHub');
///   },
/// );
/// ```
Future<Result<T>> retryOperation<T>(
  Future<T> Function() operation, {
  RetryConfig? config,
  void Function(int, Object)? onRetry,
  String context = 'RetryOperation',
}) async {
  final retryConfig = config ?? RetryConfig.githubApi;
  int attempt = 0;
  Duration delay = retryConfig.initialDelay;

  while (attempt <= retryConfig.maxRetries) {
    try {
      final result = await operation();
      return Result.success(result);
    } catch (e, stackTrace) {
      attempt++;

      // Log the error
      Logger.e(
        'Operation failed (attempt $attempt/${retryConfig.maxRetries + 1})',
        error: e,
        stackTrace: stackTrace,
        context: context,
      );

      // Check if we should retry
      if (attempt > retryConfig.maxRetries) {
        return Result.failure(ErrorHandler.handleErrorMessage(e));
      }

      // Check if exception is retryable
      if (!retryConfig.retryableExceptions.any((t) => e.runtimeType == t)) {
        return Result.failure(ErrorHandler.handleErrorMessage(e));
      }

      // Notify retry callback
      onRetry?.call(attempt, e);

      // Wait before retrying
      await Future.delayed(delay);

      // Calculate next delay with exponential backoff
      final nextDelay = (delay.inMilliseconds * retryConfig.backoffMultiplier)
          .round();
      delay = Duration(milliseconds: nextDelay);
      if (delay > retryConfig.maxDelay) {
        delay = retryConfig.maxDelay;
      }
    }
  }

  return Result.failure('Unexpected retry failure');
}
