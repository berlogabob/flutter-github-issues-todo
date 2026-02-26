/// Performance metric for tracking operation latency
class PerformanceMetric {
  final String operation;
  final String context;
  final DateTime startTime;
  DateTime? endTime;
  bool isSuccess;
  int? errorCode;
  String? errorMessage;

  PerformanceMetric({
    required this.operation,
    required this.context,
    required this.startTime,
    this.isSuccess = true,
    this.errorCode,
    this.errorMessage,
  });

  void complete({bool success = true, int? errorCode, String? errorMessage}) {
    endTime = DateTime.now();
    isSuccess = success;
    this.errorCode = errorCode;
    this.errorMessage = errorMessage;
  }

  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;

  @override
  String toString() {
    final status = isSuccess ? '✅' : '❌';
    return '$status $operation ($context): ${duration.inMilliseconds}ms'
        '${!isSuccess ? ' [${errorCode ?? 0}] $errorMessage' : ''}';
  }
}

/// Aggregated metrics for a specific operation
class OperationMetrics {
  final String operation;
  final String context;
  int _totalCalls = 0;
  int _successCount = 0;
  int _failureCount = 0;
  Duration _totalDuration = Duration.zero;

  OperationMetrics(this.operation, this.context);

  OperationMetricSummary get summary {
    final avgMs = _totalCalls > 0
        ? (_totalDuration.inMilliseconds / _totalCalls).round()
        : 0;
    final successRate = _totalCalls > 0
        ? ((_successCount / _totalCalls) * 100).round()
        : 0;
    return OperationMetricSummary(
      operation: operation,
      context: context,
      totalCalls: _totalCalls,
      successCount: _successCount,
      failureCount: _failureCount,
      averageLatencyMs: avgMs,
      successRatePercent: successRate,
    );
  }

  void record(PerformanceMetric metric) {
    _totalCalls++;
    if (metric.isSuccess) {
      _successCount++;
    } else {
      _failureCount++;
    }
    _totalDuration += metric.duration;
  }
}

/// Summary of operation metrics
class OperationMetricSummary {
  final String operation;
  final String context;
  final int totalCalls;
  final int successCount;
  final int failureCount;
  final int averageLatencyMs;
  final int successRatePercent;

  OperationMetricSummary({
    required this.operation,
    required this.context,
    required this.totalCalls,
    required this.successCount,
    required this.failureCount,
    required this.averageLatencyMs,
    required this.successRatePercent,
  });

  String get statusEmoji {
    if (successRatePercent >= 95) return '✅';
    if (successRatePercent >= 80) return '⚠️';
    return '❌';
  }

  @override
  String toString() {
    return '$statusEmoji $operation ($context): '
        '$totalCalls calls, $averageLatencyMs ms avg, $successRatePercent% success';
  }
}
