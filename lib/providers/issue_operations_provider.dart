import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../models/pending_operation.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../utils/app_error_handler.dart';

/// Optimistic issue operation for rollback support
class OptimisticOperation {
  final String id;
  final OperationType type;
  final IssueItem? originalIssue;
  final IssueItem newIssue;
  final DateTime timestamp;

  OptimisticOperation({
    required this.id,
    required this.type,
    this.originalIssue,
    required this.newIssue,
    required this.timestamp,
  });
}

/// State for issue operations with optimistic updates
class IssueOperationsState {
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final String? error;
  final List<OptimisticOperation> pendingOperations;
  final IssueItem? lastCreatedIssue;

  IssueOperationsState({
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.error,
    this.pendingOperations = const [],
    this.lastCreatedIssue,
  });

  IssueOperationsState copyWith({
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    String? error,
    List<OptimisticOperation>? pendingOperations,
    IssueItem? lastCreatedIssue,
  }) {
    return IssueOperationsState(
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error ?? this.error,
      pendingOperations: pendingOperations ?? this.pendingOperations,
      lastCreatedIssue: lastCreatedIssue ?? this.lastCreatedIssue,
    );
  }
}

/// Notifier for issue operations with optimistic updates
class IssueOperationsNotifier extends AsyncNotifier<IssueOperationsState> {
  final GitHubApiService _githubApi = GitHubApiService();
  final LocalStorageService _localStorage = LocalStorageService();

  String? _extractRepoFullName(IssueItem issue) {
    final parts = issue.id.split('/');
    if (parts.length >= 2) {
      return '${parts[0]}/${parts[1]}';
    }
    return null;
  }

  @override
  Future<IssueOperationsState> build() async {
    return IssueOperationsState();
  }

  /// Get current state safely
  IssueOperationsState get _currentState {
    return state.value ?? IssueOperationsState();
  }

  /// Create issue with optimistic update
  Future<IssueItem?> createIssueOptimistic({
    required String owner,
    required String repo,
    required String title,
    String? body,
    List<String>? labels,
    String? assignee,
  }) async {
    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    // Create optimistic issue
    final optimisticIssue = IssueItem(
      id: tempId,
      title: title,
      bodyMarkdown: body,
      labels: labels ?? [],
      assigneeLogin: assignee,
      status: ItemStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isLocalOnly: true,
    );

    // Add optimistic operation for rollback
    final operation = OptimisticOperation(
      id: tempId,
      type: OperationType.createIssue,
      newIssue: optimisticIssue,
      timestamp: DateTime.now(),
    );

    try {
      // Update state optimistically
      state = AsyncValue.data(
        _currentState.copyWith(
          isCreating: true,
          error: null,
          pendingOperations: [..._currentState.pendingOperations, operation],
        ),
      );

      // Save to local storage immediately (offline-first)
      await _localStorage.saveLocalIssue(optimisticIssue);

      // Create on GitHub
      final createdIssue = await _githubApi.createIssue(
        owner,
        repo,
        title: title,
        body: body,
        labels: labels,
        assignee: assignee,
      );

      // Remove from pending operations
      final updatedOperations = _currentState.pendingOperations
          .where((op) => op.id != tempId)
          .toList();

      // Update state with success
      state = AsyncValue.data(
        _currentState.copyWith(
          isCreating: false,
          pendingOperations: updatedOperations,
          lastCreatedIssue: createdIssue,
        ),
      );

      debugPrint('Issue created successfully: #${createdIssue.number}');
      return createdIssue;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      // Rollback: Remove optimistic issue from local storage
      await _localStorage.removeLocalIssue(tempId);

      // Remove from pending operations
      final updatedOperations = _currentState.pendingOperations
          .where((op) => op.id != tempId)
          .toList();

      // Update state with error
      state = AsyncValue.data(
        _currentState.copyWith(
          isCreating: false,
          error: e.toString(),
          pendingOperations: updatedOperations,
        ),
      );

      debugPrint('Failed to create issue: $e');
      return null;
    }
  }

  /// Update issue with optimistic update
  Future<bool> updateIssueOptimistic({
    required IssueItem issue,
    String? title,
    String? body,
    List<String>? labels,
    String? assignee,
  }) async {
    final originalIssue = issue.copyWith();
    final updatedIssue = issue.copyWith(
      title: title ?? issue.title,
      bodyMarkdown: body ?? issue.bodyMarkdown,
      labels: labels ?? issue.labels,
      assigneeLogin: assignee ?? issue.assigneeLogin,
      updatedAt: DateTime.now(),
    );

    final operationId = 'update_${issue.id}_${DateTime.now().millisecondsSinceEpoch}';

    // Add optimistic operation for rollback
    final operation = OptimisticOperation(
      id: operationId,
      type: OperationType.updateIssue,
      originalIssue: originalIssue,
      newIssue: updatedIssue,
      timestamp: DateTime.now(),
    );

    try {
      // Update state optimistically
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: true,
          error: null,
          pendingOperations: [..._currentState.pendingOperations, operation],
        ),
      );

      // Update local storage immediately
      await _localStorage.saveIssueForOfflineState(
        updatedIssue,
        repoFullName: _extractRepoFullName(issue),
      );

      // Update on GitHub if not local-only
      if (!issue.isLocalOnly && issue.number != null) {
        final parts = issue.id.split('/');
        if (parts.length >= 2) {
          final owner = parts[0];
          final repo = parts[1];
          
          await _githubApi.updateIssue(
            owner,
            repo,
            issue.number!,
            title: title,
            body: body,
            labels: labels,
            assignees: assignee != null ? [assignee] : null,
          );
        }
      }

      // Remove from pending operations
      final updatedOperations = _currentState.pendingOperations
          .where((op) => op.id != operationId)
          .toList();

      // Update state with success
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: false,
          pendingOperations: updatedOperations,
        ),
      );

      debugPrint('Issue updated successfully: ${issue.id}');
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      // Rollback: Restore original issue
      await _localStorage.saveIssueForOfflineState(
        originalIssue,
        repoFullName: _extractRepoFullName(issue),
      );

      // Remove from pending operations
      final updatedOperations = _currentState.pendingOperations
          .where((op) => op.id != operationId)
          .toList();

      // Update state with error
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: false,
          error: e.toString(),
          pendingOperations: updatedOperations,
        ),
      );

      debugPrint('Failed to update issue: $e');
      return false;
    }
  }

  /// Close/reopen issue with optimistic update
  Future<bool> toggleIssueStateOptimistic({
    required IssueItem issue,
    required bool close, // true = close, false = reopen
  }) async {
    final originalIssue = issue.copyWith();
    final updatedIssue = issue.copyWith(
      status: close ? ItemStatus.closed : ItemStatus.open,
      updatedAt: DateTime.now(),
    );

    try {
      // Update state optimistically
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: true,
          error: null,
        ),
      );

      // Update local storage immediately
      await _localStorage.saveIssueForOfflineState(
        updatedIssue,
        repoFullName: _extractRepoFullName(issue),
      );

      // Update on GitHub if not local-only
      if (!issue.isLocalOnly && issue.number != null) {
        final parts = issue.id.split('/');
        if (parts.length >= 2) {
          final owner = parts[0];
          final repo = parts[1];
          
          await _githubApi.updateIssue(
            owner,
            repo,
            issue.number!,
            state: close ? 'closed' : 'open',
          );
        }
      }

      // Update state with success
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: false,
        ),
      );

      debugPrint('Issue ${close ? 'closed' : 'reopened'} successfully: ${issue.id}');
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      // Rollback: Restore original issue
      await _localStorage.saveIssueForOfflineState(
        originalIssue,
        repoFullName: _extractRepoFullName(issue),
      );

      // Update state with error
      state = AsyncValue.data(
        _currentState.copyWith(
          isUpdating: false,
          error: e.toString(),
        ),
      );

      debugPrint('Failed to toggle issue state: $e');
      return false;
    }
  }

  /// Rollback an optimistic operation
  Future<void> rollbackOperation(String operationId) async {
    final operation = _currentState.pendingOperations
        .firstWhere((op) => op.id == operationId, orElse: () => throw Exception('Operation not found'));

    try {
      // Restore original state
      if (operation.originalIssue != null) {
        await _localStorage.saveIssueForOfflineState(
          operation.originalIssue!,
          repoFullName: _extractRepoFullName(operation.newIssue),
        );
      } else if (operation.type == OperationType.createIssue) {
        // Remove the created issue
        await _localStorage.removeLocalIssue(operation.newIssue.id);
      }

      // Remove from pending operations
      final updatedOperations = _currentState.pendingOperations
          .where((op) => op.id != operationId)
          .toList();

      state = AsyncValue.data(
        _currentState.copyWith(
          pendingOperations: updatedOperations,
          error: 'Operation rolled back',
        ),
      );

      debugPrint('Rolled back operation: $operationId');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      state = AsyncValue.data(
        _currentState.copyWith(
          error: 'Rollback failed: $e',
        ),
      );
    }
  }

  /// Clear all errors
  void clearError() {
    state = AsyncValue.data(
      _currentState.copyWith(error: null),
    );
  }
}

/// Provider for issue operations
final issueOperationsProvider = AsyncNotifierProvider<IssueOperationsNotifier, IssueOperationsState>(
  IssueOperationsNotifier.new,
);
