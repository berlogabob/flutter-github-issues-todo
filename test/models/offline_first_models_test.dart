import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/models/pending_operation.dart';

void main() {
  group('Offline-first model serialization', () {
    test('IssueItem preserves repoFullName and markdown across JSON', () {
      final createdAt = DateTime.utc(2026, 5, 1, 12);
      final updatedAt = DateTime.utc(2026, 5, 2, 13, 30);
      final localUpdatedAt = DateTime.utc(2026, 5, 3, 14, 45);
      const markdown = '''
# Offline issue

- keep list formatting
- keep `inline code`

```dart
final value = 'unchanged';
```
''';

      final issue = IssueItem(
        id: 'local_1770000000000',
        title: 'Offline markdown issue',
        number: -1770000000000,
        bodyMarkdown: markdown,
        repoFullName: 'octo/offline-repo',
        labels: const ['offline', 'markdown'],
        assigneeLogin: 'octocat',
        status: ItemStatus.closed,
        createdAt: createdAt,
        updatedAt: updatedAt,
        localUpdatedAt: localUpdatedAt,
        isLocalOnly: true,
      );

      final decoded = IssueItem.fromJson(
        jsonDecode(jsonEncode(issue.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.repoFullName, 'octo/offline-repo');
      expect(decoded.bodyMarkdown, markdown);
      expect(decoded.labels, const ['offline', 'markdown']);
      expect(decoded.assigneeLogin, 'octocat');
      expect(decoded.status, ItemStatus.closed);
      expect(decoded.createdAt, createdAt);
      expect(decoded.updatedAt, updatedAt);
      expect(decoded.localUpdatedAt, localUpdatedAt);
      expect(decoded.isLocalOnly, isTrue);
    });

    test('PendingOperation.createIssue preserves local issueId', () {
      final operation = PendingOperation.createIssue(
        id: 'op-create-1',
        owner: 'octo',
        repo: 'offline-repo',
        issueId: 'local_1770000000000',
        data: {
          'title': 'Queued issue',
          'body': 'Created offline',
          'labels': ['offline'],
        },
      );

      final decoded = PendingOperation.fromJson(
        jsonDecode(jsonEncode(operation.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.id, 'op-create-1');
      expect(decoded.type, OperationType.createIssue);
      expect(decoded.issueId, 'local_1770000000000');
      expect(decoded.owner, 'octo');
      expect(decoded.repo, 'offline-repo');
      expect(decoded.data['title'], 'Queued issue');
      expect(decoded.data['labels'], ['offline']);
    });

    test('PendingOperation keeps sync payload lists after JSON decode', () {
      final operation = PendingOperation.updateIssue(
        id: 'op-update-1',
        owner: 'octo',
        repo: 'offline-repo',
        issueNumber: 42,
        data: {
          'title': 'Updated offline',
          'labels': ['bug', 123],
          'assignees': ['octocat'],
        },
      );

      final decoded = PendingOperation.fromJson(
        jsonDecode(jsonEncode(operation.toJson())) as Map<String, dynamic>,
      );

      expect(decoded.issueNumber, 42);
      expect(decoded.data, isA<Map<String, dynamic>>());
      expect(decoded.data['labels'], isA<List<dynamic>>());
      expect(decoded.data['labels'], ['bug', 123]);
      expect(decoded.data['assignees'], ['octocat']);
    });
  });
}
