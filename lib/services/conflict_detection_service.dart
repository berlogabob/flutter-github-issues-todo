import 'package:flutter/foundation.dart';
import '../models/issue_item.dart';

/// Conflict between local and remote issue changes
class IssueConflict {
  final String issueId;
  final int issueNumber;
  final IssueItem localIssue;
  final IssueItem remoteIssue;
  final List<ConflictField> conflictingFields;
  final DateTime detectedAt;

  IssueConflict({
    required this.issueId,
    required this.issueNumber,
    required this.localIssue,
    required this.remoteIssue,
    required this.conflictingFields,
    required this.detectedAt,
  });

  bool get hasTitleConflict => conflictingFields.contains(ConflictField.title);
  bool get hasBodyConflict => conflictingFields.contains(ConflictField.body);
  bool get hasLabelsConflict => conflictingFields.contains(ConflictField.labels);
  bool get hasAssigneeConflict => conflictingFields.contains(ConflictField.assignee);
  bool get hasStatusConflict => conflictingFields.contains(ConflictField.status);
}

/// Fields that can have conflicts
enum ConflictField {
  title,
  body,
  labels,
  assignee,
  status,
}

/// Conflict resolution choice
enum ResolutionChoice {
  useLocal,
  useRemote,
  merge,
}

/// Service for detecting conflicts between local and remote issues
class ConflictDetectionService {
  static final ConflictDetectionService _instance =
      ConflictDetectionService._internal();
  factory ConflictDetectionService() => _instance;
  ConflictDetectionService._internal();

  final List<IssueConflict> _detectedConflicts = [];

  /// Detect conflicts between local and remote issues
  /// Returns list of conflicts found
  List<IssueConflict> detectConflicts({
    required List<IssueItem> localIssues,
    required List<IssueItem> remoteIssues,
  }) {
    _detectedConflicts.clear();

    // Create map of remote issues by number for quick lookup
    final remoteIssuesMap = {
      for (final issue in remoteIssues) issue.number: issue
    };

    // Check each local issue for conflicts
    for (final localIssue in localIssues) {
      if (localIssue.number == null) continue;

      final remoteIssue = remoteIssuesMap[localIssue.number];
      if (remoteIssue == null) continue;

      // Skip if local issue hasn't been modified
      if (!localIssue.isLocalOnly &&
          localIssue.localUpdatedAt == null) {
        continue;
      }

      // Detect conflicting fields
      final conflictingFields = _detectConflictingFields(
        localIssue,
        remoteIssue,
      );

      if (conflictingFields.isNotEmpty) {
        final conflict = IssueConflict(
          issueId: localIssue.id,
          issueNumber: localIssue.number!,
          localIssue: localIssue,
          remoteIssue: remoteIssue,
          conflictingFields: conflictingFields,
          detectedAt: DateTime.now(),
        );

        _detectedConflicts.add(conflict);
        debugPrint(
          'ConflictDetection: Found conflict for issue #${localIssue.number} '
          'in fields: ${conflictingFields.map((e) => e.name).join(', ')}',
        );
      }
    }

    debugPrint(
      'ConflictDetection: Detected ${_detectedConflicts.length} conflicts',
    );
    return List.unmodifiable(_detectedConflicts);
  }

  /// Detect which fields have conflicts
  List<ConflictField> _detectConflictingFields(
    IssueItem local,
    IssueItem remote,
  ) {
    final conflicts = <ConflictField>[];

    // Check title conflict
    if (local.title != remote.title &&
        local.localUpdatedAt != null &&
        remote.updatedAt != null) {
      // Conflict if both were modified after last sync
      if (local.localUpdatedAt!.isAfter(remote.updatedAt!)) {
        conflicts.add(ConflictField.title);
      }
    }

    // Check body conflict
    if (local.bodyMarkdown != remote.bodyMarkdown &&
        local.localUpdatedAt != null &&
        remote.updatedAt != null) {
      if (local.localUpdatedAt!.isAfter(remote.updatedAt!)) {
        conflicts.add(ConflictField.body);
      }
    }

    // Check labels conflict
    if (!_listsEqual(local.labels, remote.labels) &&
        local.localUpdatedAt != null &&
        remote.updatedAt != null) {
      if (local.localUpdatedAt!.isAfter(remote.updatedAt!)) {
        conflicts.add(ConflictField.labels);
      }
    }

    // Check assignee conflict
    if (local.assigneeLogin != remote.assigneeLogin &&
        local.localUpdatedAt != null &&
        remote.updatedAt != null) {
      if (local.localUpdatedAt!.isAfter(remote.updatedAt!)) {
        conflicts.add(ConflictField.assignee);
      }
    }

    // Check status conflict
    if (local.status != remote.status &&
        local.localUpdatedAt != null &&
        remote.updatedAt != null) {
      if (local.localUpdatedAt!.isAfter(remote.updatedAt!)) {
        conflicts.add(ConflictField.status);
      }
    }

    return conflicts;
  }

  /// Check if two lists are equal (order-independent)
  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final sortedA = List<String>.from(a)..sort();
    final sortedB = List<String>.from(b)..sort();
    for (int i = 0; i < sortedA.length; i++) {
      if (sortedA[i] != sortedB[i]) return false;
    }
    return true;
  }

  /// Get detected conflicts
  List<IssueConflict> getConflicts() {
    return List.unmodifiable(_detectedConflicts);
  }

  /// Clear detected conflicts
  void clearConflicts() {
    _detectedConflicts.clear();
  }

  /// Get conflict count
  int getConflictCount() {
    return _detectedConflicts.length;
  }

  /// Check if there are any conflicts
  bool hasConflicts() {
    return _detectedConflicts.isNotEmpty;
  }
}
