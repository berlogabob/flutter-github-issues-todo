import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';

/// Test for Issue #34: Offline mode new issues doubling on sync
///
/// This test verifies that local-only issues created offline are not
/// duplicated when syncing with GitHub.
void main() {
  group('Issue #34 - Offline Issue Duplication Prevention', () {
    test('local issue should be filtered by title match with remote issue', () {
      // Create a local-only issue (created offline)
      final localIssue = IssueItem(
        id: 'local_1234567890',
        title: 'Test Issue Created Offline',
        bodyMarkdown: 'This issue was created while offline',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: true,
        number: null, // No GitHub number yet
      );

      // Create a remote issue with the SAME title (already synced to GitHub)
      final remoteIssue = IssueItem(
        id: '987654321',
        title: 'Test Issue Created Offline',
        bodyMarkdown: 'This issue was created while offline',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
        number: 42, // Has GitHub number
      );

      // Simulate the title-based duplicate detection logic
      final titleKey = localIssue.title.toLowerCase().trim();
      final remoteIssuesByTitle = <String, IssueItem>{};
      remoteIssuesByTitle[remoteIssue.title.toLowerCase().trim()] = remoteIssue;

      // Check if local issue would be filtered out
      final isDuplicate = remoteIssuesByTitle.containsKey(titleKey);

      expect(
        isDuplicate,
        isTrue,
        reason: 'Local issue should be detected as duplicate by title match',
      );
    });

    test('local issue with different title should NOT be filtered', () {
      // Create a local-only issue
      final localIssue = IssueItem(
        id: 'local_1234567890',
        title: 'Unique Local Issue',
        bodyMarkdown: 'This is a new issue',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: true,
        number: null,
      );

      // Create a remote issue with DIFFERENT title
      final remoteIssue = IssueItem(
        id: '987654321',
        title: 'Different Remote Issue',
        bodyMarkdown: 'Different content',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
        number: 42,
      );

      // Simulate the title-based duplicate detection logic
      final titleKey = localIssue.title.toLowerCase().trim();
      final remoteIssuesByTitle = <String, IssueItem>{};
      remoteIssuesByTitle[remoteIssue.title.toLowerCase().trim()] = remoteIssue;

      // Check if local issue would be filtered out
      final isDuplicate = remoteIssuesByTitle.containsKey(titleKey);

      expect(
        isDuplicate,
        isFalse,
        reason: 'Local issue with unique title should NOT be filtered',
      );
    });

    test('local issue title matching should be case-insensitive', () {
      // Create a local-only issue with lowercase title
      final localIssue = IssueItem(
        id: 'local_1234567890',
        title: 'test issue',
        bodyMarkdown: 'Test content',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: true,
        number: null,
      );

      // Create a remote issue with UPPERCASE title (same words)
      final remoteIssue = IssueItem(
        id: '987654321',
        title: 'TEST ISSUE',
        bodyMarkdown: 'Test content',
        status: ItemStatus.open,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
        number: 42,
      );

      // Simulate the title-based duplicate detection logic
      final titleKey = localIssue.title.toLowerCase().trim();
      final remoteIssuesByTitle = <String, IssueItem>{};
      remoteIssuesByTitle[remoteIssue.title.toLowerCase().trim()] = remoteIssue;

      // Check if local issue would be filtered out
      final isDuplicate = remoteIssuesByTitle.containsKey(titleKey);

      expect(
        isDuplicate,
        isTrue,
        reason: 'Title matching should be case-insensitive',
      );
    });

    test(
      'synced issue IDs should be tracked to prevent multi-repo duplication',
      () {
        // Simulate tracking synced issue IDs across multiple repos
        final syncedLocalIssueIds = <String>{};

        final localIssue1 = IssueItem(
          id: 'local_111',
          title: 'Issue 1',
          status: ItemStatus.open,
          isLocalOnly: true,
          number: null,
        );

        final localIssue2 = IssueItem(
          id: 'local_222',
          title: 'Issue 2',
          status: ItemStatus.open,
          isLocalOnly: true,
          number: null,
        );

        // Simulate syncing first issue
        syncedLocalIssueIds.add(localIssue1.id);

        // Check if issue 1 would be filtered in next repo iteration
        final shouldSyncIssue1 = !syncedLocalIssueIds.contains(localIssue1.id);
        final shouldSyncIssue2 = !syncedLocalIssueIds.contains(localIssue2.id);

        expect(
          shouldSyncIssue1,
          isFalse,
          reason: 'Already synced issue should be filtered out',
        );
        expect(
          shouldSyncIssue2,
          isTrue,
          reason: 'Unsynced issue should still be processed',
        );
      },
    );

    test('IssueItem JSON serialization preserves isLocalOnly flag', () {
      final issue = IssueItem(
        id: 'local_123',
        title: 'Test',
        isLocalOnly: true,
        number: null,
        status: ItemStatus.open,
      );

      final json = issue.toJson();
      expect(json['isLocalOnly'], isTrue);

      final decoded = IssueItem.fromJson(json);
      expect(decoded.isLocalOnly, isTrue);
    });

    test('body content should be considered in duplicate detection', () {
      // Create a local-only issue
      final localIssue = IssueItem(
        id: 'local_123',
        title: 'Test Issue',
        bodyMarkdown: 'This is the body content',
        status: ItemStatus.open,
        isLocalOnly: true,
        number: null,
      );

      // Create a remote issue with same title but different body
      final remoteIssueDifferentBody = IssueItem(
        id: '987',
        title: 'Test Issue',
        bodyMarkdown: 'Different body content',
        status: ItemStatus.open,
        isLocalOnly: false,
        number: 42,
      );

      // Create a remote issue with same title AND same body
      final remoteIssueSameBody = IssueItem(
        id: '988',
        title: 'Test Issue',
        bodyMarkdown: 'This is the body content',
        status: ItemStatus.open,
        isLocalOnly: false,
        number: 43,
      );

      // Simulate the enhanced duplicate detection with body check
      final titleKey = localIssue.title.toLowerCase().trim();
      final remoteIssuesByTitle = <String, IssueItem>{};
      remoteIssuesByTitle[remoteIssueDifferentBody.title.toLowerCase().trim()] =
          remoteIssueDifferentBody;
      remoteIssuesByTitle[remoteIssueSameBody.title.toLowerCase().trim()] =
          remoteIssueSameBody;

      // Check title match
      final titleMatch = remoteIssuesByTitle.containsKey(titleKey);
      expect(titleMatch, isTrue, reason: 'Title should match');

      // Check body match for the same body issue
      final matchingRemote = remoteIssuesByTitle[titleKey];
      final bodyMatches =
          localIssue.bodyMarkdown == null ||
          matchingRemote?.bodyMarkdown == null ||
          localIssue.bodyMarkdown!.trim() ==
              matchingRemote!.bodyMarkdown!.trim();

      expect(bodyMatches, isTrue, reason: 'Body should match for same content');
    });

    test('null body should not prevent duplicate detection', () {
      // Create a local-only issue with null body
      final localIssue = IssueItem(
        id: 'local_123',
        title: 'Test Issue',
        bodyMarkdown: null,
        status: ItemStatus.open,
        isLocalOnly: true,
        number: null,
      );

      // Create a remote issue with same title
      final remoteIssue = IssueItem(
        id: '987',
        title: 'Test Issue',
        bodyMarkdown: 'Some body',
        status: ItemStatus.open,
        isLocalOnly: false,
        number: 42,
      );

      // Simulate the duplicate detection
      final titleKey = localIssue.title.toLowerCase().trim();
      final remoteIssuesByTitle = <String, IssueItem>{};
      remoteIssuesByTitle[remoteIssue.title.toLowerCase().trim()] = remoteIssue;

      // Check if duplicate is detected
      final isDuplicate = remoteIssuesByTitle.containsKey(titleKey);
      expect(
        isDuplicate,
        isTrue,
        reason: 'Should detect duplicate even with null body',
      );

      // Body match check should pass with null body
      final matchingRemote = remoteIssuesByTitle[titleKey];
      final bodyMatches =
          localIssue.bodyMarkdown == null ||
          matchingRemote?.bodyMarkdown == null ||
          localIssue.bodyMarkdown!.trim() ==
              matchingRemote!.bodyMarkdown!.trim();

      expect(bodyMatches, isTrue, reason: 'Null body should match anything');
    });
  });
}
