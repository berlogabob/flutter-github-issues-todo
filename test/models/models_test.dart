import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/repo_item.dart';

void main() {
  group('IssueItem Model', () {
    test('should create IssueItem with required fields', () {
      final issue = IssueItem(
        id: 'issue-1',
        title: 'Test Issue',
        number: 1,
      );

      expect(issue.id, 'issue-1');
      expect(issue.title, 'Test Issue');
      expect(issue.number, 1);
      expect(issue.status, ItemStatus.open);
      expect(issue.bodyMarkdown, isNull);
      expect(issue.projectColumnName, isNull);
      expect(issue.children, isEmpty);
      expect(issue.labels, isEmpty);
      expect(issue.isLocalOnly, isFalse);
    });

    test('should create IssueItem with all fields', () {
      final now = DateTime.now();
      final issue = IssueItem(
        id: 'issue-1',
        title: 'Test Issue',
        number: 42,
        bodyMarkdown: '# Test\nThis is a test issue',
        projectColumnName: 'In Progress',
        projectItemNodeId: 'node-123',
        status: ItemStatus.open,
        updatedAt: now,
        assigneeLogin: 'developer',
        labels: ['feature', 'ui'],
        isExpanded: true,
      );

      expect(issue.number, 42);
      expect(issue.bodyMarkdown, contains('# Test'));
      expect(issue.projectColumnName, 'In Progress');
      expect(issue.projectItemNodeId, 'node-123');
      expect(issue.assigneeLogin, 'developer');
      expect(issue.labels, hasLength(2));
      expect(issue.labels.contains('feature'), isTrue);
      expect(issue.isExpanded, isTrue);
    });

    test('should serialize IssueItem to JSON', () {
      final issue = IssueItem(
        id: 'issue-1',
        title: 'Test Issue',
        number: 1,
        bodyMarkdown: 'Description',
        projectColumnName: 'Todo',
        status: ItemStatus.open,
        labels: ['bug'],
      );

      final json = issue.toJson();

      expect(json['id'], 'issue-1');
      expect(json['title'], 'Test Issue');
      expect(json['number'], 1);
      expect(json['bodyMarkdown'], 'Description');
      expect(json['projectColumnName'], 'Todo');
      expect(json['status'], 'open');
      expect(json['labels'], contains('bug'));
    });

    test('should deserialize IssueItem from JSON', () {
      final json = {
        'id': 'issue-1',
        'title': 'Test Issue',
        'number': 100,
        'bodyMarkdown': 'Issue body',
        'projectColumnName': 'Done',
        'status': 'closed',
        'assigneeLogin': 'user',
        'labels': ['enhancement'],
      };

      final issue = IssueItem.fromJson(json);

      expect(issue.number, 100);
      expect(issue.bodyMarkdown, 'Issue body');
      expect(issue.projectColumnName, 'Done');
      expect(issue.status, ItemStatus.closed);
      expect(issue.assigneeLogin, 'user');
      expect(issue.labels, hasLength(1));
      expect(issue.labels.first, 'enhancement');
    });

    test('should handle null values in IssueItem.fromJson', () {
      final json = {
        'id': 'issue-1',
        'title': 'Test Issue',
        'number': null,
        'bodyMarkdown': null,
        'projectColumnName': null,
        'status': 'open',
        'labels': null,
      };

      final issue = IssueItem.fromJson(json);

      expect(issue.number, isNull);
      expect(issue.bodyMarkdown, isNull);
      expect(issue.projectColumnName, isNull);
      expect(issue.labels, isEmpty);
    });

    test('should copy IssueItem with changes', () {
      final original = IssueItem(
        id: 'issue-1',
        title: 'Original',
        number: 1,
        status: ItemStatus.open,
      );

      final copy = IssueItem(
        id: original.id,
        title: 'Updated',
        number: original.number,
        status: ItemStatus.closed,
        bodyMarkdown: original.bodyMarkdown,
        projectColumnName: original.projectColumnName,
        projectItemNodeId: original.projectItemNodeId,
        updatedAt: DateTime.now(),
        assigneeLogin: original.assigneeLogin,
        labels: original.labels,
        isLocalOnly: original.isLocalOnly,
      );

      expect(copy.title, 'Updated');
      expect(copy.status, ItemStatus.closed);
    });
  });

  group('RepoItem Model', () {
    test('should create RepoItem with required fields', () {
      final repo = RepoItem(
        id: 'repo-1',
        title: 'test-repo',
        fullName: 'user/test-repo',
      );

      expect(repo.id, 'repo-1');
      expect(repo.title, 'test-repo');
      expect(repo.fullName, 'user/test-repo');
      expect(repo.description, isNull);
      expect(repo.children, isEmpty);
    });

    test('should create RepoItem with children (issues)', () {
      final issue = IssueItem(
        id: 'issue-1',
        title: 'Bug fix',
        number: 1,
      );

      final repo = RepoItem(
        id: 'repo-1',
        title: 'test-repo',
        fullName: 'user/test-repo',
        description: 'Test repository',
        children: [issue],
      );

      expect(repo.children, hasLength(1));
      expect(repo.children.first.title, 'Bug fix');
      expect(repo.children.first, isA<IssueItem>());
    });

    test('should serialize RepoItem to JSON', () {
      final repo = RepoItem(
        id: 'repo-1',
        title: 'test-repo',
        fullName: 'user/test-repo',
        description: 'Description',
      );

      final json = repo.toJson();

      expect(json['id'], 'repo-1');
      expect(json['title'], 'test-repo');
      expect(json['fullName'], 'user/test-repo');
      expect(json['description'], 'Description');
      expect(json['children'], isList);
    });

    test('should deserialize RepoItem from JSON', () {
      final json = {
        'id': 'repo-1',
        'title': 'test-repo',
        'fullName': 'owner/test-repo',
        'description': 'A test repo',
        'children': [],
      };

      final repo = RepoItem.fromJson(json);

      expect(repo.fullName, 'owner/test-repo');
      expect(repo.description, 'A test repo');
      expect(repo.children, isEmpty);
    });

    test('should add issue to repo children', () {
      final repo = RepoItem(
        id: 'repo-1',
        title: 'test-repo',
        fullName: 'user/test-repo',
        children: [], // Empty modifiable list
      );

      final issue = IssueItem(
        id: 'issue-1',
        title: 'New issue',
        number: 1,
      );

      repo.children.add(issue);

      expect(repo.children, hasLength(1));
      expect(repo.children.first.id, 'issue-1');
    });
  });

  group('ItemStatus Enum', () {
    test('should have open and closed values', () {
      expect(ItemStatus.values, hasLength(2));
      expect(ItemStatus.values[0], ItemStatus.open);
      expect(ItemStatus.values[1], ItemStatus.closed);
    });

    test('should use status extension methods', () {
      expect(ItemStatus.open.isOpen, isTrue);
      expect(ItemStatus.open.isClosed, isFalse);
      expect(ItemStatus.closed.isOpen, isFalse);
      expect(ItemStatus.closed.isClosed, isTrue);
    });
  });

  group('Integration Tests', () {
    test('should create repo with multiple issues', () {
      final issues = List.generate(
        5,
        (i) => IssueItem(
          id: 'issue-$i',
          title: 'Issue $i',
          number: i + 1,
          status: i % 2 == 0 ? ItemStatus.open : ItemStatus.closed,
          labels: i % 2 == 0 ? ['bug'] : ['feature'],
        ),
      );

      final repo = RepoItem(
        id: 'repo-1',
        title: 'test-repo',
        fullName: 'user/test-repo',
        children: issues,
      );

      expect(repo.children, hasLength(5));
      expect(repo.children.where((i) => i.status == ItemStatus.open), hasLength(3));
      expect(repo.children.where((i) => i.status == ItemStatus.closed), hasLength(2));
    });

    test('should filter issues by status', () {
      final issues = [
        IssueItem(id: '1', title: 'Open 1', number: 1, status: ItemStatus.open),
        IssueItem(id: '2', title: 'Closed 1', number: 2, status: ItemStatus.closed),
        IssueItem(id: '3', title: 'Open 2', number: 3, status: ItemStatus.open),
      ];

      final openIssues = issues.where((i) => i.status.isOpen).toList();
      final closedIssues = issues.where((i) => i.status.isClosed).toList();

      expect(openIssues, hasLength(2));
      expect(closedIssues, hasLength(1));
    });
  });
}
