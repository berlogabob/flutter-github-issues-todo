import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Retry Helper with Exponential Backoff
/// Provides retry logic for API calls with configurable:
/// - Max retries
/// - Initial delay
/// - Max delay
/// - Backoff multiplier
/// - Custom retry conditions
class RetryHelper {
  final int maxRetries;
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffMultiplier;

  const RetryHelper({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 30),
    this.backoffMultiplier = 2.0,
  });

  /// Execute a function with retry logic
  /// 
  /// Example:
  /// ```dart
  /// final retryHelper = RetryHelper(maxRetries: 3);
  /// final result = await retryHelper.execute(
  ///   () => githubApi.fetchIssues(owner, repo),
  ///   shouldRetry: (e) => e is SocketException || e is TimeoutException,
  /// );
  /// ```
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
    bool Function(Object error)? shouldRetry,
    void Function(int attempt, Object error, Duration delay)? onRetry,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        attempt++;
        debugPrint('RetryHelper: Attempt $attempt/${maxRetries + 1} ${operationName ?? ''}');
        
        return await operation();
      } catch (e) {
        debugPrint('RetryHelper: Error on attempt $attempt: $e');

        // Check if we should retry
        final canRetry = attempt <= maxRetries;
        final shouldRetryThisError = shouldRetry?.call(e) ?? _isRetryableError(e);

        if (!canRetry || !shouldRetryThisError) {
          debugPrint('RetryHelper: Not retrying - max attempts reached or non-retryable error');
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delayMs = currentDelay.inMilliseconds;
        final clampedDelayMs = delayMs > maxDelay.inMilliseconds ? maxDelay.inMilliseconds : delayMs;
        final delay = Duration(milliseconds: clampedDelayMs);
        debugPrint('RetryHelper: Retrying in ${delay.inMilliseconds}ms...');

        // Call onRetry callback if provided
        onRetry?.call(attempt, e, delay);

        // Wait before retrying
        await Future.delayed(delay);

        // Increase delay for next retry (exponential backoff)
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).round(),
        );
      }
    }
  }

  /// Check if error is retryable
  /// By default, retry on:
  /// - Network errors (SocketException)
  /// - Timeout errors
  /// - HTTP 5xx errors
  /// - HTTP 429 (rate limit)
  bool _isRetryableError(Object error) {
    if (error is SocketException) {
      debugPrint('RetryHelper: Retryable - SocketException (network error)');
      return true;
    }

    if (error is TimeoutException) {
      debugPrint('RetryHelper: Retryable - TimeoutException');
      return true;
    }

    if (error is HttpException) {
      debugPrint('RetryHelper: HttpException - ${error.message}');
      return true;
    }

    // Check for HTTP status codes in error message
    final errorMessage = error.toString().toLowerCase();
    if (errorMessage.contains('503') || // Service Unavailable
        errorMessage.contains('502') || // Bad Gateway
        errorMessage.contains('504') || // Gateway Timeout
        errorMessage.contains('429')) { // Rate Limit
      debugPrint('RetryHelper: Retryable - HTTP ${errorMessage.contains('503') ? '503' : errorMessage.contains('429') ? '429' : '5xx'}');
      return true;
    }

    debugPrint('RetryHelper: Not retryable - $error');
    return false;
  }

  /// Execute with simple retry (no custom conditions)
  Future<T> simpleRetry<T>(Future<T> Function() operation) async {
    return execute(operation);
  }

  /// Execute with custom delay
  Future<T> executeWithDelay<T>(
    Future<T> Function() operation, {
    required Duration delay,
    int retries = 3,
  }) async {
    int attempt = 0;

    while (attempt <= retries) {
      try {
        attempt++;
        return await operation();
      } catch (e) {
        if (attempt > retries) rethrow;
        
        debugPrint('RetryHelper: Retrying in ${delay.inSeconds}s...');
        await Future.delayed(delay);
      }
    }

    throw Exception('Unexpected error in retry logic');
  }
}

/// Extension on Future for easy retry
extension RetryExtension<T> on Future<T> {
  /// Retry the future with default settings
  Future<T> withRetry({
    int maxRetries = 3,
    Duration initialDelay = const Duration(seconds: 1),
  }) async {
    final retryHelper = RetryHelper(
      maxRetries: maxRetries,
      initialDelay: initialDelay,
    );
    return retryHelper.execute(() => this);
  }
}

/// API Call Tracker for monitoring retry statistics
class ApiCallTracker {
  static final ApiCallTracker _instance = ApiCallTracker._internal();
  factory ApiCallTracker() => _instance;
  ApiCallTracker._internal();

  int _totalCalls = 0;
  int _successfulCalls = 0;
  int _failedCalls = 0;
  int _retryAttempts = 0;
  DateTime? _lastCallTime;
  Duration _totalLatency = Duration.zero;

  void recordCall({
    required bool success,
    required Duration latency,
    int retryCount = 0,
  }) {
    _totalCalls++;
    _lastCallTime = DateTime.now();
    _totalLatency += latency;

    if (success) {
      _successfulCalls++;
    } else {
      _failedCalls++;
    }

    _retryAttempts += retryCount;
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'totalCalls': _totalCalls,
      'successfulCalls': _successfulCalls,
      'failedCalls': _failedCalls,
      'retryAttempts': _retryAttempts,
      'successRate': _totalCalls > 0 ? (_successfulCalls / _totalCalls * 100).toStringAsFixed(1) : '0.0',
      'averageLatency': _totalCalls > 0 
          ? Duration(milliseconds: _totalLatency.inMilliseconds ~/ _totalCalls)
          : Duration.zero,
      'lastCallTime': _lastCallTime,
    };
  }

  /// Reset statistics
  void reset() {
    _totalCalls = 0;
    _successfulCalls = 0;
    _failedCalls = 0;
    _retryAttempts = 0;
    _totalLatency = Duration.zero;
    _lastCallTime = null;
  }

  @override
  String toString() {
    final stats = getStats();
    return 'ApiCallTracker(calls: $_totalCalls, success: ${stats['successRate']}%, retries: $_retryAttempts)';
  }
}
