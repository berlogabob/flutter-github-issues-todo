import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:gitdoit/models/issue.dart';
import 'package:gitdoit/models/issue.adapter.dart';

/// Hive Caching Tests
///
/// Tests for verifying Hive caching functionality:
/// 1. Issues save on create
/// 2. Issues load on startup
/// 3. Cache persists after app restart
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late Box<Issue> issuesBox;

  setUpAll(() async {
    // Set up temporary directory for Hive
    tempDir = await Directory.systemTemp.createTemp('hive_test_');

    // Initialize Hive with temp directory
    Hive.init(tempDir.path);

    // Register adapters
    Hive.registerAdapter(IssueAdapter());
    Hive.registerAdapter(LabelAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(UserAdapter());
  });

  setUp(() async {
    // Open a fresh box for each test
    issuesBox = await Hive.openBox<Issue>('test_issues');
  });

  tearDown(() async {
    // Close and delete box after each test
    await issuesBox.close();
    await Hive.deleteBoxFromDisk('test_issues');
  });

  tearDownAll(() async {
    // Clean up temp directory
    await tempDir.delete(recursive: true);
  });

  group('Hive Caching Tests', () {
    test('1) Issues save on create', () async {
      // Create test issues
      final issue1 = Issue(
        number: 1,
        title: 'Test Issue 1',
        body: 'Test body 1',
        state: 'open',
        createdAt: DateTime.now(),
        labels: [Label(name: 'bug', color: 'ff0000')],
        assignees: [],
      );

      final issue2 = Issue(
        number: 2,
        title: 'Test Issue 2',
        body: 'Test body 2',
        state: 'open',
        createdAt: DateTime.now(),
        labels: [],
        assignees: [],
      );

      // Save issues to Hive (simulating _saveToCache with string keys)
      await issuesBox.clear();
      for (final issue in [issue1, issue2]) {
        await issuesBox.put('issue_${issue.number}', issue);
      }

      // Verify issues were saved
      expect(issuesBox.length, 2);
      expect(issuesBox.get('issue_${issue1.number}')?.number, 1);
      expect(issuesBox.get('issue_${issue1.number}')?.title, 'Test Issue 1');
      expect(issuesBox.get('issue_${issue2.number}')?.number, 2);
      expect(issuesBox.get('issue_${issue2.number}')?.title, 'Test Issue 2');

      // Verify issue properties are preserved
      final savedIssue1 = issuesBox.get('issue_${issue1.number}');
      expect(savedIssue1?.state, 'open');
      expect(savedIssue1?.isOpen, true);
      expect(savedIssue1?.labels.length, 1);
      expect(savedIssue1?.labels.first.name, 'bug');
    });

    test('2) Issues load on startup', () async {
      // Pre-populate box with issues
      final issue1 = Issue(
        number: 10,
        title: 'Cached Issue 1',
        body: 'Cached body 1',
        state: 'open',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 2),
        labels: [Label(name: 'feature', color: '00ff00')],
        assignees: [User(login: 'user1')],
      );

      final issue2 = Issue(
        number: 20,
        title: 'Cached Issue 2',
        body: 'Cached body 2',
        state: 'closed',
        createdAt: DateTime(2024, 1, 3),
        closedAt: DateTime(2024, 1, 4),
        labels: [],
        assignees: [],
      );

      await issuesBox.put('issue_${issue1.number}', issue1);
      await issuesBox.put('issue_${issue2.number}', issue2);

      // Simulate startup - reopen box (fresh instance)
      await issuesBox.close();
      final reopenedBox = await Hive.openBox<Issue>('test_issues');

      try {
        // Load issues from cache (simulating _loadFromCache)
        final cachedIssues = reopenedBox.values.toList();

        // Verify issues were loaded
        expect(cachedIssues.length, 2);

        // Verify issue data integrity
        final loadedIssue1 = cachedIssues.firstWhere((i) => i.number == 10);
        expect(loadedIssue1.title, 'Cached Issue 1');
        expect(loadedIssue1.body, 'Cached body 1');
        expect(loadedIssue1.state, 'open');
        expect(loadedIssue1.createdAt, DateTime(2024, 1, 1));
        expect(loadedIssue1.updatedAt, DateTime(2024, 1, 2));
        expect(loadedIssue1.labels.length, 1);
        expect(loadedIssue1.labels.first.name, 'feature');
        expect(loadedIssue1.assignees.length, 1);
        expect(loadedIssue1.assignees.first.login, 'user1');

        final loadedIssue2 = cachedIssues.firstWhere((i) => i.number == 20);
        expect(loadedIssue2.title, 'Cached Issue 2');
        expect(loadedIssue2.state, 'closed');
        expect(loadedIssue2.isClosed, true);
        expect(loadedIssue2.closedAt, DateTime(2024, 1, 4));
      } finally {
        await reopenedBox.close();
      }
    });

    test('3) Cache persists after app restart', () async {
      // Create and save multiple issues with various states
      final issues = [
        Issue(
          number: 100,
          title: 'Persistent Issue 1',
          body: 'This should persist',
          state: 'open',
          createdAt: DateTime(2024, 2, 1),
          updatedAt: DateTime(2024, 2, 2),
          labels: [
            Label(name: 'bug', color: 'ff0000', description: 'Bug'),
            Label(name: 'priority', color: 'ffff00'),
          ],
          assignees: [User(login: 'dev1', name: 'Developer 1')],
          milestone: Milestone(
            number: 1,
            title: 'v1.0',
            state: 'open',
            createdAt: DateTime(2024, 1, 1),
          ),
          user: User(login: 'creator'),
        ),
        Issue(
          number: 101,
          title: 'Persistent Issue 2',
          body: 'Another persistent issue',
          state: 'closed',
          createdAt: DateTime(2024, 2, 3),
          updatedAt: DateTime(2024, 2, 4),
          closedAt: DateTime(2024, 2, 5),
          labels: [],
          assignees: [],
        ),
        Issue(
          number: 102,
          title: 'Persistent Issue 3',
          state: 'open',
          createdAt: DateTime(2024, 2, 6),
          labels: [Label(name: 'enhancement', color: '0000ff')],
          assignees: [],
        ),
      ];

      // Save all issues using string keys
      await issuesBox.clear();
      for (final issue in issues) {
        await issuesBox.put('issue_${issue.number}', issue);
      }

      // Verify save
      expect(issuesBox.length, 3);

      // Simulate app restart - close all boxes and reopen
      await issuesBox.close();
      await Hive.close();

      // Reinitialize Hive (simulating fresh app start)
      // Note: In real app, adapters are registered once at startup
      // Here we just reopen the box without re-registering adapters
      Hive.init(tempDir.path);

      // Reopen box
      final restartedBox = await Hive.openBox<Issue>('test_issues');

      try {
        // Load all issues
        final persistedIssues = restartedBox.values.toList();

        // Verify all issues persisted
        expect(persistedIssues.length, 3);

        // Verify each issue's data integrity
        final issue1 = persistedIssues.firstWhere((i) => i.number == 100);
        expect(issue1.title, 'Persistent Issue 1');
        expect(issue1.body, 'This should persist');
        expect(issue1.isOpen, true);
        expect(issue1.labels.length, 2);
        expect(issue1.assignees.first.name, 'Developer 1');
        expect(issue1.milestone?.title, 'v1.0');
        expect(issue1.user?.login, 'creator');

        final issue2 = persistedIssues.firstWhere((i) => i.number == 101);
        expect(issue2.title, 'Persistent Issue 2');
        expect(issue2.isClosed, true);
        expect(issue2.closedAt, DateTime(2024, 2, 5));

        final issue3 = persistedIssues.firstWhere((i) => i.number == 102);
        expect(issue3.title, 'Persistent Issue 3');
        expect(issue3.labels.first.name, 'enhancement');

        // Verify data types are preserved
        expect(issue1.createdAt, DateTime(2024, 2, 1));
        expect(issue1.updatedAt, DateTime(2024, 2, 2));
      } finally {
        await restartedBox.close();
      }
    });

    test('Cache handles empty state correctly', () async {
      // Verify empty box behavior
      expect(issuesBox.isEmpty, true);
      expect(issuesBox.values.toList().isEmpty, true);

      // Clear empty box should not throw
      await issuesBox.clear();
      expect(issuesBox.isEmpty, true);
    });

    test('Cache handles issue updates', () async {
      // Create initial issue
      final issue = Issue(
        number: 50,
        title: 'Original Title',
        state: 'open',
        createdAt: DateTime.now(),
        assignees: [],
      );

      await issuesBox.put('issue_${issue.number}', issue);

      // Update issue
      final updatedIssue = issue.copyWith(
        title: 'Updated Title',
        state: 'closed',
        updatedAt: DateTime.now(),
      );

      await issuesBox.put('issue_${updatedIssue.number}', updatedIssue);

      // Verify update
      final savedIssue = issuesBox.get('issue_${updatedIssue.number}');
      expect(savedIssue?.title, 'Updated Title');
      expect(savedIssue?.isClosed, true);
      expect(savedIssue?.number, 50); // Number should remain same
    });

    test('Cache handles issue deletion', () async {
      // Add multiple issues
      final issue1 = Issue(
        number: 1,
        title: 'Issue 1',
        state: 'open',
        createdAt: DateTime.now(),
        assignees: [],
      );
      final issue2 = Issue(
        number: 2,
        title: 'Issue 2',
        state: 'open',
        createdAt: DateTime.now(),
        assignees: [],
      );

      await issuesBox.put('issue_${issue1.number}', issue1);
      await issuesBox.put('issue_${issue2.number}', issue2);
      expect(issuesBox.length, 2);

      // Delete one issue
      await issuesBox.delete('issue_${issue1.number}');
      expect(issuesBox.length, 1);
      expect(issuesBox.get('issue_${issue1.number}'), isNull);
      expect(issuesBox.get('issue_${issue2.number}')?.number, 2);
    });

    test('Cache preserves all Issue model fields', () async {
      final now = DateTime.now();
      final issue = Issue(
        number: 999,
        title: 'Complete Issue Test',
        body: 'Full body content',
        state: 'open',
        createdAt: now,
        updatedAt: now,
        closedAt: null,
        labels: [
          Label(
            id: 1,
            name: 'label1',
            color: 'aabbcc',
            description: 'Test label',
            url: 'https://example.com',
          ),
        ],
        milestone: Milestone(
          number: 5,
          title: 'Test Milestone',
          description: 'Milestone description',
          state: 'open',
          createdAt: now,
          updatedAt: now,
          closedAt: null,
          dueOn: DateTime(2024, 12, 31),
          closedIssues: 10,
          openIssues: 5,
        ),
        assignee: User(login: 'assignee1', id: 123),
        assignees: [
          User(
            login: 'assignee1',
            id: 123,
            avatarUrl: 'https://example.com/avatar.png',
          ),
          User(login: 'assignee2', id: 456, name: 'Assignee Two'),
        ],
        htmlUrl: 'https://github.com/owner/repo/issues/999',
        repositoryUrl: 'https://api.github.com/repos/owner/repo',
        user: User(
          login: 'creator',
          id: 789,
          name: 'Creator Name',
          email: 'creator @example.com',
          company: 'Test Corp',
          blog: 'https://example.com',
          location: 'San Francisco',
          bio: 'Test bio',
        ),
      );

      await issuesBox.put('issue_${issue.number}', issue);

      // Verify all fields are preserved
      final savedIssue = issuesBox.get('issue_${issue.number}');
      expect(savedIssue, isNotNull);
      expect(savedIssue?.number, 999);
      expect(savedIssue?.title, 'Complete Issue Test');
      expect(savedIssue?.body, 'Full body content');
      expect(savedIssue?.state, 'open');
      expect(savedIssue?.createdAt, now);
      expect(savedIssue?.updatedAt, now);
      expect(savedIssue?.closedAt, isNull);
      expect(savedIssue?.labels.length, 1);
      expect(savedIssue?.labels.first.id, 1);
      expect(savedIssue?.labels.first.description, 'Test label');
      expect(savedIssue?.milestone?.number, 5);
      expect(savedIssue?.milestone?.dueOn, DateTime(2024, 12, 31));
      expect(savedIssue?.assignee?.login, 'assignee1');
      expect(savedIssue?.assignees.length, 2);
      expect(savedIssue?.htmlUrl, 'https://github.com/owner/repo/issues/999');
      expect(
        savedIssue?.repositoryUrl,
        'https://api.github.com/repos/owner/repo',
      );
      expect(savedIssue?.user?.email, 'creator @example.com');
      expect(savedIssue?.user?.company, 'Test Corp');
    });
  });

  group('IssuesProvider Cache Integration Tests', () {
    test('_saveToCache and _loadFromCache simulation', () async {
      // Simulate IssuesProvider cache operations
      final testIssues = [
        Issue(
          number: 1,
          title: 'Issue One',
          state: 'open',
          createdAt: DateTime.now(),
          assignees: [],
        ),
        Issue(
          number: 2,
          title: 'Issue Two',
          state: 'closed',
          createdAt: DateTime.now(),
          assignees: [],
        ),
        Issue(
          number: 3,
          title: 'Issue Three',
          state: 'open',
          createdAt: DateTime.now(),
          assignees: [],
        ),
      ];

      // Simulate _saveToCache (using string keys)
      await issuesBox.clear();
      for (final issue in testIssues) {
        await issuesBox.put('issue_${issue.number}', issue);
      }

      // Simulate _loadFromCache
      final cachedIssues = issuesBox.values.toList();

      expect(cachedIssues.length, 3);
      expect(cachedIssues.any((i) => i.number == 1), true);
      expect(cachedIssues.any((i) => i.number == 2), true);
      expect(cachedIssues.any((i) => i.number == 3), true);
    });

    test('Cache merge simulation (local + remote)', () async {
      // Simulate existing cached (local) issues
      // Note: Using string keys allows negative issue numbers for local-only issues
      final localIssues = [
        Issue(
          number: -1, // Local-only issue (negative number)
          title: 'Local Issue',
          state: 'open',
          createdAt: DateTime.now(),
          assignees: [],
        ),
      ];

      // Save local issues using string keys
      await issuesBox.clear();
      for (final issue in localIssues) {
        await issuesBox.put('issue_${issue.number}', issue);
      }

      // Simulate remote issues from GitHub
      final remoteIssues = [
        Issue(
          number: 1,
          title: 'Remote Issue 1',
          state: 'open',
          createdAt: DateTime.now(),
          assignees: [],
        ),
        Issue(
          number: 2,
          title: 'Remote Issue 2',
          state: 'open',
          createdAt: DateTime.now(),
          assignees: [],
        ),
      ];

      // Simulate merge (remote takes precedence, local-only preserved)
      final remoteMap = {for (var issue in remoteIssues) issue.number: issue};
      final merged = <Issue>[...remoteIssues];

      for (final localIssue in localIssues) {
        if (!remoteMap.containsKey(localIssue.number)) {
          merged.add(localIssue);
        }
      }

      // Save merged results using string keys
      await issuesBox.clear();
      for (final issue in merged) {
        await issuesBox.put('issue_${issue.number}', issue);
      }

      // Verify merge
      expect(issuesBox.length, 3);
      final cachedIssues = issuesBox.values.toList();
      final numbers = cachedIssues.map((i) => i.number).toList();
      expect(numbers, contains(-1)); // Local issue preserved
      expect(numbers, contains(1)); // Remote issue present
      expect(numbers, contains(2)); // Remote issue present
    });
  });
}
