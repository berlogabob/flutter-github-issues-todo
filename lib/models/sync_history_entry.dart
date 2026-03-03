/// Sync history entry model
class SyncHistoryEntry {
  final String id;
  final DateTime timestamp;
  final SyncResult result;
  final int issuesSynced;
  final int projectsSynced;
  final int operationsProcessed;
  final String? errorMessage;
  final Duration duration;

  SyncHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.result,
    this.issuesSynced = 0,
    this.projectsSynced = 0,
    this.operationsProcessed = 0,
    this.errorMessage,
    this.duration = Duration.zero,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'result': result.name,
      'issuesSynced': issuesSynced,
      'projectsSynced': projectsSynced,
      'operationsProcessed': operationsProcessed,
      'errorMessage': errorMessage,
      'durationMs': duration.inMilliseconds,
    };
  }

  factory SyncHistoryEntry.fromJson(Map<String, dynamic> json) {
    return SyncHistoryEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      result: SyncResult.values.firstWhere(
        (e) => e.name == json['result'],
        orElse: () => SyncResult.success,
      ),
      issuesSynced: json['issuesSynced'] as int? ?? 0,
      projectsSynced: json['projectsSynced'] as int? ?? 0,
      operationsProcessed: json['operationsProcessed'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
      duration: Duration(milliseconds: json['durationMs'] as int? ?? 0),
    );
  }
}

/// Sync result enumeration
enum SyncResult {
  success,
  partial,
  failed,
}

/// Sync statistics model
class SyncStatistics {
  final int totalSyncs;
  final int successfulSyncs;
  final int failedSyncs;
  final int totalIssuesSynced;
  final int totalOperationsProcessed;
  final DateTime? lastSyncTime;
  final DateTime? lastSuccessfulSync;

  SyncStatistics({
    this.totalSyncs = 0,
    this.successfulSyncs = 0,
    this.failedSyncs = 0,
    this.totalIssuesSynced = 0,
    this.totalOperationsProcessed = 0,
    this.lastSyncTime,
    this.lastSuccessfulSync,
  });

  double get successRate {
    if (totalSyncs == 0) return 0.0;
    return (successfulSyncs / totalSyncs) * 100;
  }

  Map<String, dynamic> toJson() {
    return {
      'totalSyncs': totalSyncs,
      'successfulSyncs': successfulSyncs,
      'failedSyncs': failedSyncs,
      'totalIssuesSynced': totalIssuesSynced,
      'totalOperationsProcessed': totalOperationsProcessed,
      'lastSyncTime': lastSyncTime?.toIso8601String(),
      'lastSuccessfulSync': lastSuccessfulSync?.toIso8601String(),
      'successRate': successRate,
    };
  }

  factory SyncStatistics.fromJson(Map<String, dynamic> json) {
    return SyncStatistics(
      totalSyncs: json['totalSyncs'] as int? ?? 0,
      successfulSyncs: json['successfulSyncs'] as int? ?? 0,
      failedSyncs: json['failedSyncs'] as int? ?? 0,
      totalIssuesSynced: json['totalIssuesSynced'] as int? ?? 0,
      totalOperationsProcessed: json['totalOperationsProcessed'] as int? ?? 0,
      lastSyncTime: json['lastSyncTime'] != null
          ? DateTime.parse(json['lastSyncTime'] as String)
          : null,
      lastSuccessfulSync: json['lastSuccessfulSync'] != null
          ? DateTime.parse(json['lastSuccessfulSync'] as String)
          : null,
    );
  }
}
