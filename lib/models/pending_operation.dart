/// Operation types that can be queued for sync
enum OperationType {
  createIssue,
  updateIssue,
  closeIssue,
  reopenIssue,
  addComment,
  updateLabels,
  updateAssignee,
}

/// Pending operation model
class PendingOperation {
  final String id;
  final OperationType type;
  final String? issueId;
  final int? issueNumber;
  final String? owner;
  final String? repo;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  bool isSyncing;
  int retryCount;

  PendingOperation({
    required this.id,
    required this.type,
    this.issueId,
    this.issueNumber,
    this.owner,
    this.repo,
    required this.data,
    required this.createdAt,
    this.isSyncing = false,
    this.retryCount = 0,
  });

  factory PendingOperation.createIssue({
    required String id,
    required String owner,
    required String repo,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.createIssue,
      owner: owner,
      repo: repo,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.updateIssue({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
    required Map<String, dynamic> data,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.updateIssue,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: data,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'issueId': issueId,
      'issueNumber': issueNumber,
      'owner': owner,
      'repo': repo,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'isSyncing': isSyncing,
      'retryCount': retryCount,
    };
  }

  factory PendingOperation.fromJson(Map<String, dynamic> json) {
    return PendingOperation(
      id: json['id'] as String,
      type: OperationType.values.firstWhere((e) => e.name == json['type']),
      issueId: json['issueId'] as String?,
      issueNumber: json['issueNumber'] as int?,
      owner: json['owner'] as String?,
      repo: json['repo'] as String?,
      data: Map<String, dynamic>.from(json['data']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isSyncing: json['isSyncing'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
    );
  }
}
