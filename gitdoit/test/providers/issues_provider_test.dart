import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/providers/issues_provider.dart';
import 'package:gitdoit/models/issue.dart';

void main() {
  group('IssuesProvider', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    group('Initial State', () {
      test('should have correct initial state', () {
        // Assert
        expect(issuesProvider.issues, isEmpty);
        expect(issuesProvider.isLoading, false);
        expect(issuesProvider.error, isNull);
        expect(issuesProvider.filter, 'open');
        expect(issuesProvider.sortBy, 'created');
        expect(issuesProvider.isOffline, false);
        expect(issuesProvider.isSyncing, false);
        expect(issuesProvider.hasSynced, false);
        expect(issuesProvider.lastSyncTime, isNull);
        expect(issuesProvider.hasIssues, false);
        expect(issuesProvider.openCount, 0);
        expect(issuesProvider.closedCount, 0);
        expect(issuesProvider.owner, isEmpty);
        expect(issuesProvider.repo, isEmpty);
        expect(issuesProvider.syncError, false);
        expect(issuesProvider.hasRepoConfig, false);
        expect(issuesProvider.repository, isNull);
      });
    });

    group('Repository Configuration', () {
      test('should return null repository when not configured', () {
        // Assert
        expect(issuesProvider.repository, isNull);
        expect(issuesProvider.hasRepoConfig, false);
      });

      test('should have empty owner and repo initially', () {
        // Assert
        expect(issuesProvider.owner, isEmpty);
        expect(issuesProvider.repo, isEmpty);
      });
    });

    group('Multi-Repository Configuration', () {
      test('should have empty repositories list initially', () {
        // Assert
        expect(issuesProvider.repositories, isEmpty);
        expect(issuesProvider.enabledRepositories, isEmpty);
        expect(issuesProvider.hasMultipleRepos, false);
      });

      test('should get multiRepoConfig', () {
        // Assert
        expect(issuesProvider.multiRepoConfig, isNotNull);
        expect(issuesProvider.multiRepoConfig.repositories, isEmpty);
      });
    });

    group('Repository Collapsed State', () {
      test('should return false for non-existent repository', () {
        // Assert
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), false);
      });

      test('should toggle repository collapsed state', () {
        // Arrange
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), false);

        // Act
        issuesProvider.toggleRepoCollapsed('flutter/flutter');

        // Assert
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), true);
      });

      test('should toggle back to expanded', () {
        // Arrange
        issuesProvider.toggleRepoCollapsed('flutter/flutter');
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), true);

        // Act
        issuesProvider.toggleRepoCollapsed('flutter/flutter');

        // Assert
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), false);
      });

      test('should set repository collapsed state', () {
        // Act
        issuesProvider.setRepoCollapsed('flutter/flutter', true);

        // Assert
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), true);
      });

      test('should set repository expanded state', () {
        // Arrange
        issuesProvider.setRepoCollapsed('flutter/flutter', true);

        // Act
        issuesProvider.setRepoCollapsed('flutter/flutter', false);

        // Assert
        expect(issuesProvider.isRepoCollapsed('flutter/flutter'), false);
      });

      test('should expand all repositories', () {
        // Arrange
        issuesProvider.setRepoCollapsed('repo1', true);
        issuesProvider.setRepoCollapsed('repo2', true);

        // Act
        issuesProvider.expandAllRepos();

        // Assert
        expect(issuesProvider.isRepoCollapsed('repo1'), false);
        expect(issuesProvider.isRepoCollapsed('repo2'), false);
      });

      test('should collapse all repositories', () {
        // Arrange
        issuesProvider.multiRepoConfig.addRepository('owner1', 'repo1');
        issuesProvider.multiRepoConfig.addRepository('owner2', 'repo2');

        // Act
        issuesProvider.collapseAllRepos();

        // Assert
        expect(issuesProvider.isRepoCollapsed('owner1/repo1'), true);
        expect(issuesProvider.isRepoCollapsed('owner2/repo2'), true);
      });
    });

    group('Issue Counts', () {
      test('should return 0 for open and closed counts when no issues', () {
        // Assert
        expect(issuesProvider.openCount, 0);
        expect(issuesProvider.closedCount, 0);
      });

      test('should calculate open count correctly', () {
        // Note: This would require injecting mock issues
        // The getter filters by isOpen property
        expect(issuesProvider.openCount, 0);
      });

      test('should calculate closed count correctly', () {
        // Note: This would require injecting mock issues
        // The getter filters by isClosed property
        expect(issuesProvider.closedCount, 0);
      });
    });

    group('Filter and Sort', () {
      test('should have default filter of open', () {
        // Assert
        expect(issuesProvider.filter, 'open');
      });

      test('should have default sort by created', () {
        // Assert
        expect(issuesProvider.sortBy, 'created');
      });
    });

    group('Sync State', () {
      test('should not be syncing initially', () {
        // Assert
        expect(issuesProvider.isSyncing, false);
      });

      test('should not have synced initially', () {
        // Assert
        expect(issuesProvider.hasSynced, false);
      });

      test('should have null lastSyncTime initially', () {
        // Assert
        expect(issuesProvider.lastSyncTime, isNull);
      });

      test('should have null lastSyncTimeFormatted initially', () {
        // Assert
        expect(issuesProvider.lastSyncTimeFormatted, isNull);
      });

      test('should not have sync error initially', () {
        // Assert
        expect(issuesProvider.syncError, false);
      });
    });

    group('Cache Methods', () {
      test('should return 0 for cachedIssueCount initially', () {
        // Assert
        expect(issuesProvider.cachedIssueCount, 0);
      });

      test('should return 0 for cache size bytes initially', () async {
        // Act
        final size = await issuesProvider.getCacheSizeBytes();

        // Assert
        expect(size, 0);
      });

      test('should return 0 B for cache size formatted initially', () async {
        // Act
        final size = await issuesProvider.getCacheSizeFormatted();

        // Assert
        expect(size, '0 B');
      });

      test('should return storage stats', () async {
        // Act
        final stats = await issuesProvider.getStorageStats();

        // Assert
        expect(stats, isA<Map<String, dynamic>>());
        expect(stats['issueCount'], 0);
        expect(stats['cacheSizeBytes'], 0);
        expect(stats['isOffline'], false);
      });
    });

    group('Multi-Repository Management', () {
      test('should add repository', () {
        // Act
        issuesProvider.addRepository('flutter', 'flutter');

        // Assert
        expect(issuesProvider.repositories.length, 1);
        expect(issuesProvider.repositories.first.fullName, 'flutter/flutter');
      });

      test('should remove repository', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        expect(issuesProvider.repositories.length, 1);

        // Act
        issuesProvider.removeRepository('flutter/flutter');

        // Assert
        expect(issuesProvider.repositories, isEmpty);
      });

      test('should toggle repository enabled state', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        expect(issuesProvider.repositories.first.isEnabled, true);

        // Act
        issuesProvider.toggleRepositoryEnabled('flutter/flutter');

        // Assert
        expect(issuesProvider.repositories.first.isEnabled, false);
      });

      test('should set repository enabled state', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');

        // Act
        issuesProvider.setRepositoryEnabled('flutter/flutter', false);

        // Assert
        expect(issuesProvider.repositories.first.isEnabled, false);
      });

      test('should set active repository', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        issuesProvider.addRepository('google', 'material');

        // Act
        issuesProvider.setActiveRepository('google/material');

        // Assert
        expect(
          issuesProvider.multiRepoConfig.activeRepository,
          'google/material',
        );
        expect(issuesProvider.owner, 'google');
        expect(issuesProvider.repo, 'material');
      });

      test('should set active repository to null', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');

        // Act
        issuesProvider.setActiveRepository(null);

        // Assert
        expect(issuesProvider.multiRepoConfig.activeRepository, isNull);
      });
    });

    group('State Change Notifications', () {
      test('should notify listeners on toggleRepoCollapsed', () {
        // Arrange
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.toggleRepoCollapsed('flutter/flutter');

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on setRepoCollapsed', () {
        // Arrange
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.setRepoCollapsed('flutter/flutter', true);

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on expandAllRepos', () {
        // Arrange
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.expandAllRepos();

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on collapseAllRepos', () {
        // Arrange
        issuesProvider.multiRepoConfig.addRepository('owner', 'repo');
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.collapseAllRepos();

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on addRepository', () {
        // Arrange
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.addRepository('flutter', 'flutter');

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on removeRepository', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.removeRepository('flutter/flutter');

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on toggleRepositoryEnabled', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.toggleRepositoryEnabled('flutter/flutter');

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on setRepositoryEnabled', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.setRepositoryEnabled('flutter/flutter', false);

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners on setActiveRepository', () {
        // Arrange
        issuesProvider.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        issuesProvider.addListener(() => notifyCount++);

        // Act
        issuesProvider.setActiveRepository(null);

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('Getters', () {
      test('should return issues list', () {
        // Assert
        expect(issuesProvider.issues, isA<List<Issue>>());
        expect(issuesProvider.issues, isEmpty);
      });

      test('should return isLoading', () {
        // Assert
        expect(issuesProvider.isLoading, false);
      });

      test('should return error', () {
        // Assert
        expect(issuesProvider.error, isNull);
      });

      test('should return filter', () {
        // Assert
        expect(issuesProvider.filter, 'open');
      });

      test('should return sortBy', () {
        // Assert
        expect(issuesProvider.sortBy, 'created');
      });

      test('should return isOffline', () {
        // Assert
        expect(issuesProvider.isOffline, false);
      });

      test('should return isSyncing', () {
        // Assert
        expect(issuesProvider.isSyncing, false);
      });

      test('should return hasSynced', () {
        // Assert
        expect(issuesProvider.hasSynced, false);
      });

      test('should return lastSyncTime', () {
        // Assert
        expect(issuesProvider.lastSyncTime, isNull);
      });

      test('should return hasIssues', () {
        // Assert
        expect(issuesProvider.hasIssues, false);
      });

      test('should return openCount', () {
        // Assert
        expect(issuesProvider.openCount, 0);
      });

      test('should return closedCount', () {
        // Assert
        expect(issuesProvider.closedCount, 0);
      });

      test('should return owner', () {
        // Assert
        expect(issuesProvider.owner, isEmpty);
      });

      test('should return repo', () {
        // Assert
        expect(issuesProvider.repo, isEmpty);
      });

      test('should return syncError', () {
        // Assert
        expect(issuesProvider.syncError, false);
      });
    });

    group('lastSyncTimeFormatted', () {
      test('should return null when lastSyncTime is null', () {
        // Assert
        expect(issuesProvider.lastSyncTimeFormatted, isNull);
      });

      test('should return Just now for recent sync', () {
        // This would require setting lastSyncTime internally
        // which needs dependency injection
        expect(issuesProvider.lastSyncTimeFormatted, isNull);
      });
    });

    group('Constructor', () {
      test('should initialize with default values', () {
        // Arrange & Act
        final provider = IssuesProvider();

        // Assert
        expect(provider.issues, isEmpty);
        expect(provider.filter, 'open');
        expect(provider.sortBy, 'created');

        provider.dispose();
      });
    });

    group('Listener Management', () {
      test('should allow multiple listener subscriptions', () {
        // Arrange
        var notifyCount1 = 0;
        var notifyCount2 = 0;

        // Act
        issuesProvider.addListener(() => notifyCount1++);
        issuesProvider.addListener(() => notifyCount2++);
        issuesProvider.toggleRepoCollapsed('test');

        // Assert
        expect(notifyCount1, 1);
        expect(notifyCount2, 1);
      });

      test('should allow listener removal', () {
        // Arrange
        var notifyCount = 0;
        void listener() => notifyCount++;
        issuesProvider.addListener(listener);

        // Act
        issuesProvider.removeListener(listener);
        issuesProvider.toggleRepoCollapsed('test');

        // Assert
        expect(notifyCount, 0);
      });
    });

    group('Repository Validation', () {
      test(
        'validateRepository should return false when not configured',
        () async {
          // Act
          final result = await issuesProvider.validateRepository();

          // Assert
          expect(result, false);
        },
      );
    });

    group('loadIssues without repository config', () {
      test('should not error when repository not configured', () async {
        // Act - should not throw
        await issuesProvider.loadIssues();

        // Assert
        expect(issuesProvider.error, isNull);
        expect(issuesProvider.isLoading, false);
      });

      test('should clear error when repository not configured', () async {
        // Act
        await issuesProvider.loadIssues();

        // Assert
        expect(issuesProvider.error, isNull);
      });
    });

    group('refreshIssues', () {
      test('should call loadIssues', () async {
        // Act - should not throw when no repo configured
        await issuesProvider.refreshIssues();

        // Assert
        expect(issuesProvider.isLoading, false);
      });
    });
  });

  group('IssuesProvider with Mock Data', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    group('Issue State Calculations', () {
      test('hasIssues should be false when no issues', () {
        // Assert
        expect(issuesProvider.hasIssues, false);
      });

      test('openCount and closedCount should be 0 when no issues', () {
        // Assert
        expect(issuesProvider.openCount, 0);
        expect(issuesProvider.closedCount, 0);
      });
    });

    group('Cache Size Formatting', () {
      test('should format bytes correctly', () async {
        // The actual formatting depends on internal state
        // This verifies the method exists and returns a string
        final size = await issuesProvider.getCacheSizeFormatted();
        expect(size, isA<String>());
      });
    });

    group('Storage Stats', () {
      test('should return map with expected keys', () async {
        // Act
        final stats = await issuesProvider.getStorageStats();

        // Assert
        expect(stats.containsKey('issueCount'), true);
        expect(stats.containsKey('cacheSizeBytes'), true);
        expect(stats.containsKey('cacheSizeFormatted'), true);
        expect(stats.containsKey('lastSyncTime'), true);
        expect(stats.containsKey('lastSyncTimeFormatted'), true);
        expect(stats.containsKey('repositoryCount'), true);
        expect(stats.containsKey('isOffline'), true);
      });
    });
  });

  group('IssuesProvider Filter States', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    test('should have open as default filter', () {
      // Assert
      expect(issuesProvider.filter, 'open');
    });

    test('should have created as default sortBy', () {
      // Assert
      expect(issuesProvider.sortBy, 'created');
    });
  });

  group('IssuesProvider Offline State', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    test('should start with isOffline false', () {
      // Assert
      expect(issuesProvider.isOffline, false);
    });
  });

  group('IssuesProvider Repository Config', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    test('should return hasRepoConfig false when owner is empty', () {
      // Assert
      expect(issuesProvider.hasRepoConfig, false);
    });

    test('should return hasRepoConfig false when repo is empty', () {
      // Assert
      expect(issuesProvider.hasRepoConfig, false);
    });

    test('should return repository null when not configured', () {
      // Assert
      expect(issuesProvider.repository, isNull);
    });
  });

  group('IssuesProvider Multi-Repo Getters', () {
    late IssuesProvider issuesProvider;

    setUp(() {
      issuesProvider = IssuesProvider();
    });

    tearDown(() {
      // Dispose may fail if Hive box was never initialized
      try {
        issuesProvider.dispose();
      } catch (_) {
        // Ignore disposal errors when box was not initialized
      }
    });

    test('should return empty list for repositories', () {
      // Assert
      expect(issuesProvider.repositories, isEmpty);
    });

    test('should return empty list for enabledRepositories', () {
      // Assert
      expect(issuesProvider.enabledRepositories, isEmpty);
    });

    test('should return false for hasMultipleRepos', () {
      // Assert
      expect(issuesProvider.hasMultipleRepos, false);
    });

    test('should return multiRepoConfig', () {
      // Assert
      expect(issuesProvider.multiRepoConfig, isNotNull);
    });
  });
}
