import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';

void main() {
  group('IssueItem', () {
    test('fromJson creates valid instance', () {
      final json = {
        'id': '123',
        'title': 'Test Issue',
        'number': 1,
        'status': 'open',
        'labels': ['bug', 'priority'],
        'assigneeLogin': 'user1',
        'bodyMarkdown': 'Test body',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-02T00:00:00Z',
      };

      final issue = IssueItem.fromJson(json);

      expect(issue.id, '123');
      expect(issue.title, 'Test Issue');
      expect(issue.number, 1);
      expect(issue.status, ItemStatus.open);
      expect(issue.labels, ['bug', 'priority']);
      expect(issue.assigneeLogin, 'user1');
      expect(issue.bodyMarkdown, 'Test body');
    });

    test('toJson creates valid JSON', () {
      final issue = IssueItem(
        id: '123',
        title: 'Test Issue',
        number: 1,
        status: ItemStatus.open,
        labels: ['bug'],
        assigneeLogin: 'user1',
        bodyMarkdown: 'Test body',
      );

      final json = issue.toJson();

      expect(json['id'], '123');
      expect(json['title'], 'Test Issue');
      expect(json['number'], 1);
      expect(json['status'], 'open');
      expect(json['labels'], ['bug']);
      expect(json['assigneeLogin'], 'user1');
      expect(json['bodyMarkdown'], 'Test body');
    });

    test('copyWith creates modified instance', () {
      final issue = IssueItem(
        id: '123',
        title: 'Original',
        number: 1,
        status: ItemStatus.open,
      );

      final modified = issue.copyWith(title: 'Modified');

      expect(issue.title, 'Original');
      expect(modified.title, 'Modified');
      expect(modified.id, '123');
      expect(modified.number, 1);
    });

    test('local issue has isLocalOnly true', () {
      final issue = IssueItem(
        id: 'local_123',
        title: 'Local Issue',
        isLocalOnly: true,
        isExpanded: false,
      );

      expect(issue.isLocalOnly, true);
      expect(issue.number, isNull);
    });
  });
}
