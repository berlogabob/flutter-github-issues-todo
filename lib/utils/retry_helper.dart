import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Retry Helper with Exponential Backoff
/// Provides retry logic for API calls with configurable:
/// - Max retries
/// - Initial delay
/// - Max delay
/// - Backoff multiplier
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
  Future<T> execute<T>(
    Future<T> Function() operation, {
    String? operationName,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      try {
        attempt++;
        debugPrint(
          'RetryHelper: Attempt $attempt/${maxRetries + 1} ${operationName ?? ''}',
        );

        return await operation();
      } catch (e) {
        debugPrint('RetryHelper: Error on attempt $attempt: $e');

        final canRetry = attempt <= maxRetries;
        if (!canRetry || !_isRetryableError(e)) {
          debugPrint(
            'RetryHelper: Not retrying - max attempts reached or non-retryable error',
          );
          rethrow;
        }

        // Calculate delay with exponential backoff
        final delayMs = currentDelay.inMilliseconds;
        final clampedDelayMs = delayMs > maxDelay.inMilliseconds
            ? maxDelay.inMilliseconds
            : delayMs;
        final delay = Duration(milliseconds: clampedDelayMs);
        debugPrint('RetryHelper: Retrying in ${delay.inMilliseconds}ms...');

        await Future.delayed(delay);

        // Increase delay for next retry (exponential backoff)
        currentDelay = Duration(
          milliseconds: (currentDelay.inMilliseconds * backoffMultiplier)
              .round(),
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
        errorMessage.contains('429')) {
      // Rate Limit
      debugPrint(
        'RetryHelper: Retryable - HTTP ${errorMessage.contains('503')
            ? '503'
            : errorMessage.contains('429')
            ? '429'
            : '5xx'}',
      );
      return true;
    }

    debugPrint('RetryHelper: Not retryable - $error');
    return false;
  }
}
