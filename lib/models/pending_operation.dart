/// Operation types that can be queued for sync
enum OperationType {
  createIssue,
  updateIssue,
  closeIssue,
  reopenIssue,
  addComment,
  deleteComment,
  updateLabels,
  updateAssignee,
}

/// Operation status for tracking sync progress
enum OperationStatus {
  pending,
  syncing,
  completed,
  failed,
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
  OperationStatus status;
  bool isSyncing;
  int retryCount;
  String? errorMessage;

  PendingOperation({
    required this.id,
    required this.type,
    this.issueId,
    this.issueNumber,
    this.owner,
    this.repo,
    required this.data,
    required this.createdAt,
    this.status = OperationStatus.pending,
    this.isSyncing = false,
    this.retryCount = 0,
    this.errorMessage,
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

  factory PendingOperation.closeIssue({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.closeIssue,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {},
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.reopenIssue({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.reopenIssue,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {},
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.addComment({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
    required String body,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.addComment,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {'body': body},
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.deleteComment({
    required String id,
    required int commentId,
    required int issueNumber,
    required String owner,
    required String repo,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.deleteComment,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {'commentId': commentId},
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.updateLabels({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
    required List<String> labels,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.updateLabels,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {'labels': labels},
      createdAt: DateTime.now(),
    );
  }

  factory PendingOperation.updateAssignee({
    required String id,
    required int issueNumber,
    required String owner,
    required String repo,
    required String? assignee,
  }) {
    return PendingOperation(
      id: id,
      type: OperationType.updateAssignee,
      issueNumber: issueNumber,
      owner: owner,
      repo: repo,
      data: {'assignee': assignee},
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
      'status': status.name,
      'isSyncing': isSyncing,
      'retryCount': retryCount,
      'errorMessage': errorMessage,
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
      status: OperationStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OperationStatus.pending,
      ),
      isSyncing: json['isSyncing'] as bool? ?? false,
      retryCount: json['retryCount'] as int? ?? 0,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
