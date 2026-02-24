import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/issue.dart';
import '../utils/logger.dart';

/// Issues Cache - Handles Hive local caching operations
///
/// Responsible for:
/// - Opening/closing Hive boxes
/// - Saving issues to cache
/// - Loading issues from cache
/// - Cache cleanup
class IssuesCache extends ChangeNotifier {
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  // Hive box for local caching
  Box<Issue>? _issuesBox;

  // Helper to check if Hive box is available
  bool get isBoxAvailable => _issuesBox != null && _issuesBox!.isOpen;

  /// Initialize Hive box for issues caching
  Future<void> initialize() async {
    final metric = Logger.startMetric('initialize', 'IssuesCache');
    try {
      _issuesBox = await Hive.openBox<Issue>('issues');
      Logger.i('Hive box opened', context: 'IssuesCache');
      metric.complete(success: true);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to initialize Hive',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesCache',
      );
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Close Hive box
  Future<void> close() async {
    if (_issuesBox != null && _issuesBox!.isOpen) {
      await _issuesBox!.close();
      _issuesBox = null;
      Logger.d('Hive box closed', context: 'IssuesCache');
      notifyListeners();
    }
  }

  /// Save issues to Hive cache
  ///
  /// Uses issue numbers as keys for reliable persistence and updates
  Future<void> saveToCache(List<Issue> issues) async {
    if (!isBoxAvailable) return;

    final metric = Logger.startMetric('saveToCache', 'IssuesCache');
    try {
      // Clear existing cache
      await _issuesBox!.clear();

      // Save each issue using its number as part of the key
      // String keys support both positive (remote) and negative (local) issue numbers
      for (final issue in issues) {
        await _issuesBox!.put(_getCacheKey(issue), issue);
      }

      Logger.d('Cached ${issues.length} issues', context: 'IssuesCache');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.w('Failed to cache issues', context: 'IssuesCache');
      Logger.e(
        'Failed to cache issues',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesCache',
      );
      metric.complete(success: false, errorMessage: e.toString());
    }
  }

  /// Load issues from Hive cache
  ///
  /// Returns issues sorted by update time (most recent first)
  Future<List<Issue>> loadFromCache() async {
    if (!isBoxAvailable) return [];

    final metric = Logger.startMetric('loadFromCache', 'IssuesCache');
    try {
      final cachedIssues = _issuesBox!.values.toList();

      if (cachedIssues.isNotEmpty) {
        // Sort by updated date (most recent first)
        cachedIssues.sort((a, b) {
          final aUpdated = a.updatedAt ?? a.createdAt;
          final bUpdated = b.updatedAt ?? b.createdAt;
          return bUpdated.compareTo(aUpdated);
        });

        Logger.i(
          'Loaded ${cachedIssues.length} issues from cache',
          context: 'IssuesCache',
        );
        metric.complete(success: true);
        return cachedIssues;
      }

      Logger.d('No cached issues found', context: 'IssuesCache');
      metric.complete(success: true);
      return [];
    } catch (e, stackTrace) {
      Logger.w('Failed to load from cache', context: 'IssuesCache');
      Logger.e(
        'Failed to load from cache',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesCache',
      );
      metric.complete(success: false, errorMessage: e.toString());
      return [];
    }
  }

  /// Clear all cached issues
  Future<void> clearCache() async {
    if (!isBoxAvailable) return;

    final metric = Logger.startMetric('clearCache', 'IssuesCache');
    try {
      await _issuesBox!.clear();
      Logger.i('Cache cleared', context: 'IssuesCache');
      metric.complete(success: true);
      notifyListeners();
    } catch (e, stackTrace) {
      Logger.e(
        'Failed to clear cache',
        error: e,
        stackTrace: stackTrace,
        context: 'IssuesCache',
      );
      metric.complete(success: false, errorMessage: e.toString());
    }
  }

  /// Get cache key for an issue
  ///
  /// Uses string keys to support both remote (positive) and local (negative) issue numbers
  String _getCacheKey(Issue issue) => 'issue_${issue.number}';

  /// Get number of cached issues
  int get cachedIssueCount => isBoxAvailable ? _issuesBox!.length : 0;

  /// Check if a specific issue is cached
  Future<bool> isIssueCached(int issueNumber) async {
    if (!isBoxAvailable) return false;
    return await _issuesBox!.containsKey('issue_$issueNumber');
  }

  /// Remove a specific issue from cache
  Future<void> removeFromCache(int issueNumber) async {
    if (!isBoxAvailable) return;
    await _issuesBox!.delete('issue_$issueNumber');
    Logger.d('Removed issue #$issueNumber from cache', context: 'IssuesCache');
  }
}
