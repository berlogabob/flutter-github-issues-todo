import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gitdoit/models/issue.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Issue Model', () {
    // Test data
    final testCreatedAt = DateTime(2024, 1, 15, 10, 30, 0);
    final testUpdatedAt = DateTime(2024, 1, 16, 14, 45, 0);

    final testLabel = Label(
      id: 1,
      name: 'bug',
      color: 'd73a4a',
      description: 'Something isn\'t working',
      url: 'https://api.github.com/repos/owner/repo/labels/bug',
    );

    final testMilestone = Milestone(
      number: 1,
      title: 'v1.0.0',
      description: 'First release',
      state: 'open',
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      closedAt: null,
      dueOn: DateTime(2024, 6, 1),
      closedIssues: 5,
      openIssues: 10,
    );

    final testUser = User(
      login: 'testuser',
      id: 12345,
      avatarUrl: 'https://avatars.githubusercontent.com/u/12345',
      htmlUrl: 'https://github.com/testuser',
      name: 'Test User',
      email: 'test@example.com',
      company: 'Test Corp',
      blog: 'https://testuser.dev',
      location: 'San Francisco',
      bio: 'A test user',
    );

    final testIssue = Issue(
      number: 42,
      title: 'Test Issue Title',
      body: 'This is the body of the test issue',
      state: 'open',
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      closedAt: null,
      labels: [testLabel],
      milestone: testMilestone,
      assignee: testUser,
      assignees: [testUser],
      htmlUrl: 'https://github.com/owner/repo/issues/42',
      repositoryUrl: 'https://api.github.com/repos/owner/repo',
      user: testUser,
    );

    group('JSON Serialization', () {
      test('should serialize Issue to JSON', () {
        // Arrange
        final issue = testIssue;

        // Act
        final json = issue.toJson();

        // Assert
        expect(json['number'], 42);
        expect(json['title'], 'Test Issue Title');
        expect(json['body'], 'This is the body of the test issue');
        expect(json['state'], 'open');
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
        expect(json['closed_at'], isNull);
        expect(json['html_url'], 'https://github.com/owner/repo/issues/42');
        expect(
          json['repository_url'],
          'https://api.github.com/repos/owner/repo',
        );
      });

      test('should deserialize Issue from JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'number': 42,
          'title': 'Test Issue Title',
          'body': 'This is the body of the test issue',
          'state': 'open',
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
          'closed_at': null,
          'labels': [
            {
              'id': 1,
              'name': 'bug',
              'color': 'd73a4a',
              'description': 'Something isn\'t working',
              'url': 'https://api.github.com/repos/owner/repo/labels/bug',
            },
          ],
          'milestone': {
            'number': 1,
            'title': 'v1.0.0',
            'description': 'First release',
            'state': 'open',
            'created_at': testCreatedAt.toIso8601String(),
            'updated_at': testUpdatedAt.toIso8601String(),
            'closed_at': null,
            'due_on': DateTime(2024, 6, 1).toIso8601String(),
            'closed_issues': 5,
            'open_issues': 10,
          },
          'assignee': {
            'login': 'testuser',
            'id': 12345,
            'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
            'html_url': 'https://github.com/testuser',
            'name': 'Test User',
            'email': 'test@example.com',
          },
          'assignees': [
            {
              'login': 'testuser',
              'id': 12345,
              'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
              'html_url': 'https://github.com/testuser',
              'name': 'Test User',
            },
          ],
          'html_url': 'https://github.com/owner/repo/issues/42',
          'repository_url': 'https://api.github.com/repos/owner/repo',
          'user': {
            'login': 'testuser',
            'id': 12345,
            'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
          },
        };

        // Act
        final issue = Issue.fromJson(json);

        // Assert
        expect(issue.number, 42);
        expect(issue.title, 'Test Issue Title');
        expect(issue.body, 'This is the body of the test issue');
        expect(issue.state, 'open');
        expect(issue.createdAt, testCreatedAt);
        expect(issue.updatedAt, testUpdatedAt);
        expect(issue.closedAt, isNull);
        expect(issue.labels.length, 1);
        expect(issue.labels.first.name, 'bug');
        expect(issue.milestone?.title, 'v1.0.0');
        expect(issue.assignee?.login, 'testuser');
        expect(issue.assignees.length, 1);
        expect(issue.htmlUrl, 'https://github.com/owner/repo/issues/42');
      });

      test('should handle null optional fields in JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'number': 1,
          'title': 'Minimal Issue',
          'body': null,
          'state': 'open',
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': null,
          'closed_at': null,
          'labels': [],
          'milestone': null,
          'assignee': null,
          'assignees': [],
          'html_url': null,
          'repository_url': null,
          'user': null,
        };

        // Act
        final issue = Issue.fromJson(json);

        // Assert
        expect(issue.number, 1);
        expect(issue.title, 'Minimal Issue');
        expect(issue.body, isNull);
        expect(issue.labels, isEmpty);
        expect(issue.milestone, isNull);
        expect(issue.assignee, isNull);
        expect(issue.assignees, isEmpty);
        expect(issue.htmlUrl, isNull);
      });

      test('should serialize and deserialize back to same object', () {
        // Arrange
        final originalIssue = testIssue;

        // Act
        final json = originalIssue.toJson();
        final deserializedIssue = Issue.fromJson(json);

        // Assert
        expect(deserializedIssue.number, originalIssue.number);
        expect(deserializedIssue.title, originalIssue.title);
        expect(deserializedIssue.state, originalIssue.state);
        expect(deserializedIssue.createdAt, originalIssue.createdAt);
      });
    });

    group('copyWith Method', () {
      test('should create a copy with all fields unchanged', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.number, original.number);
        expect(copy.title, original.title);
        expect(copy.body, original.body);
        expect(copy.state, original.state);
        expect(copy.createdAt, original.createdAt);
        expect(copy.labels, original.labels);
        expect(copy.milestone, original.milestone);
        expect(copy.assignee, original.assignee);
        expect(copy.assignees, original.assignees);
        expect(copy.htmlUrl, original.htmlUrl);
        expect(copy.repositoryUrl, original.repositoryUrl);
        expect(copy.user, original.user);
        expect(copy, isNot(same(original)));
      });

      test('should update number field', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith(number: 100);

        // Assert
        expect(copy.number, 100);
        expect(copy.title, original.title);
      });

      test('should update title field', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith(title: 'Updated Title');

        // Assert
        expect(copy.title, 'Updated Title');
        expect(copy.number, original.number);
      });

      test('should update state field', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith(state: 'closed');

        // Assert
        expect(copy.state, 'closed');
        expect(copy.isOpen, false);
        expect(copy.isClosed, true);
      });

      test('should update body field', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith(body: 'Updated body');

        // Assert
        expect(copy.body, 'Updated body');
      });

      test('should update labels field', () {
        // Arrange
        final original = testIssue;
        final newLabel = Label(name: 'enhancement', color: 'a2eeef');

        // Act
        final copy = original.copyWith(labels: [newLabel]);

        // Assert
        expect(copy.labels.length, 1);
        expect(copy.labels.first.name, 'enhancement');
      });

      test('should update assignees field', () {
        // Arrange
        final original = testIssue;
        final newUser = User(login: 'newuser');

        // Act
        final copy = original.copyWith(assignees: [newUser]);

        // Assert
        expect(copy.assignees.length, 1);
        expect(copy.assignees.first.login, 'newuser');
      });

      test('should update multiple fields at once', () {
        // Arrange
        final original = testIssue;

        // Act
        final copy = original.copyWith(
          title: 'New Title',
          state: 'closed',
          body: 'New body',
          number: 999,
        );

        // Assert
        expect(copy.title, 'New Title');
        expect(copy.state, 'closed');
        expect(copy.body, 'New body');
        expect(copy.number, 999);
        expect(copy.createdAt, original.createdAt);
      });

      test('should preserve original value when copying with null', () {
        // Note: The copyWith pattern uses `field ?? this.field`
        // so passing null preserves the original value
        // Arrange
        final issueWithBody = testIssue;

        // Act
        final copy = issueWithBody.copyWith(body: null);

        // Assert - body is preserved (this is the copyWith pattern behavior)
        expect(copy.body, issueWithBody.body);
      });
    });

    group('Equality', () {
      test('should be equal when number, title, and state match', () {
        // Arrange
        final issue1 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );
        final issue2 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: DateTime(2025, 1, 1), // Different date
        );

        // Assert
        expect(issue1, equals(issue2));
      });

      test('should not be equal when number differs', () {
        // Arrange
        final issue1 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );
        final issue2 = Issue(
          number: 43,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue1, isNot(equals(issue2)));
      });

      test('should not be equal when title differs', () {
        // Arrange
        final issue1 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );
        final issue2 = Issue(
          number: 42,
          title: 'Different',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue1, isNot(equals(issue2)));
      });

      test('should not be equal when state differs', () {
        // Arrange
        final issue1 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );
        final issue2 = Issue(
          number: 42,
          title: 'Test',
          state: 'closed',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue1, isNot(equals(issue2)));
      });

      test('should be identical to itself', () {
        // Arrange
        final issue = testIssue;

        // Assert
        expect(issue, equals(issue));
      });

      test('should not be equal to non-Issue object', () {
        // Arrange
        final issue = testIssue;

        // Assert
        expect(issue, isNot(equals('not an issue')));
        expect(issue, isNot(equals(42)));
        expect(issue, isNot(equals(null)));
      });

      test('hashCode should be consistent', () {
        // Arrange
        final issue1 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );
        final issue2 = Issue(
          number: 42,
          title: 'Test',
          state: 'open',
          createdAt: DateTime(2025, 1, 1),
        );

        // Assert
        expect(issue1.hashCode, equals(issue2.hashCode));
      });
    });

    group('Getters', () {
      test('isOpen should return true for open state', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.isOpen, true);
      });

      test('isOpen should return false for closed state', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'closed',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.isOpen, false);
      });

      test('isClosed should return true for closed state', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'closed',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.isClosed, true);
      });

      test('isClosed should return false for open state', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.isClosed, false);
      });

      test('formattedTitle should include number and title', () {
        // Arrange
        final issue = Issue(
          number: 42,
          title: 'Test Issue',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.formattedTitle, '#42 - Test Issue');
      });

      test('formattedTitle should work with zero issue number', () {
        // Arrange
        final issue = Issue(
          number: 0,
          title: 'Local Issue',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.formattedTitle, '#0 - Local Issue');
      });
    });

    group('toString', () {
      test('should return formatted string representation', () {
        // Arrange
        final issue = Issue(
          number: 42,
          title: 'Test Issue',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.toString(), 'Issue(#42: Test Issue, state: open)');
      });
    });

    group('Default Values', () {
      test('should have empty labels list by default', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.labels, isEmpty);
      });

      test('should have empty assignees list by default', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.assignees, isEmpty);
      });

      test('should have null body by default', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.body, isNull);
      });

      test('should have null milestone by default', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.milestone, isNull);
      });

      test('should have null assignee by default', () {
        // Arrange
        final issue = Issue(
          number: 1,
          title: 'Test',
          state: 'open',
          createdAt: testCreatedAt,
        );

        // Assert
        expect(issue.assignee, isNull);
      });
    });
  });

  group('Label Model', () {
    test('should serialize Label to JSON', () {
      // Arrange
      final label = Label(
        id: 1,
        name: 'bug',
        color: 'd73a4a',
        description: 'Something isn\'t working',
        url: 'https://api.github.com/labels/bug',
      );

      // Act
      final json = label.toJson();

      // Assert
      expect(json['id'], 1);
      expect(json['name'], 'bug');
      expect(json['color'], 'd73a4a');
      expect(json['description'], 'Something isn\'t working');
      expect(json['url'], 'https://api.github.com/labels/bug');
    });

    test('should deserialize Label from JSON', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 1,
        'name': 'bug',
        'color': 'd73a4a',
        'description': 'Something isn\'t working',
        'url': 'https://api.github.com/labels/bug',
      };

      // Act
      final label = Label.fromJson(json);

      // Assert
      expect(label.id, 1);
      expect(label.name, 'bug');
      expect(label.color, 'd73a4a');
      expect(label.description, 'Something isn\'t working');
      expect(label.url, 'https://api.github.com/labels/bug');
    });

    test('should handle null id in Label', () {
      // Arrange
      final json = <String, dynamic>{'name': 'bug', 'color': 'd73a4a'};

      // Act
      final label = Label.fromJson(json);

      // Assert
      expect(label.id, isNull);
      expect(label.name, 'bug');
      expect(label.color, 'd73a4a');
    });

    test('toString should return label name', () {
      // Arrange
      final label = Label(name: 'bug', color: 'd73a4a');

      // Assert
      expect(label.toString(), 'Label(bug)');
    });
  });

  group('Milestone Model', () {
    final testCreatedAt = DateTime(2024, 1, 1);
    final testUpdatedAt = DateTime(2024, 1, 15);
    final testDueOn = DateTime(2024, 6, 1);

    test('should serialize Milestone to JSON', () {
      // Arrange
      final milestone = Milestone(
        number: 1,
        title: 'v1.0.0',
        description: 'First release',
        state: 'open',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        closedAt: null,
        dueOn: testDueOn,
        closedIssues: 5,
        openIssues: 10,
      );

      // Act
      final json = milestone.toJson();

      // Assert
      expect(json['number'], 1);
      expect(json['title'], 'v1.0.0');
      expect(json['description'], 'First release');
      expect(json['state'], 'open');
      expect(json['created_at'], testCreatedAt.toIso8601String());
      expect(json['due_on'], testDueOn.toIso8601String());
      expect(json['closed_issues'], 5);
      expect(json['open_issues'], 10);
    });

    test('should deserialize Milestone from JSON', () {
      // Arrange
      final json = <String, dynamic>{
        'number': 1,
        'title': 'v1.0.0',
        'description': 'First release',
        'state': 'open',
        'created_at': testCreatedAt.toIso8601String(),
        'updated_at': testUpdatedAt.toIso8601String(),
        'closed_at': null,
        'due_on': testDueOn.toIso8601String(),
        'closed_issues': 5,
        'open_issues': 10,
      };

      // Act
      final milestone = Milestone.fromJson(json);

      // Assert
      expect(milestone.number, 1);
      expect(milestone.title, 'v1.0.0');
      expect(milestone.description, 'First release');
      expect(milestone.state, 'open');
      expect(milestone.createdAt, testCreatedAt);
      expect(milestone.dueOn, testDueOn);
      expect(milestone.closedIssues, 5);
      expect(milestone.openIssues, 10);
    });

    test('isOpen should return true for open state', () {
      // Arrange
      final milestone = Milestone(
        number: 1,
        title: 'v1.0.0',
        state: 'open',
        createdAt: testCreatedAt,
      );

      // Assert
      expect(milestone.isOpen, true);
      expect(milestone.isClosed, false);
    });

    test('isOpen should return false for closed state', () {
      // Arrange
      final milestone = Milestone(
        number: 1,
        title: 'v1.0.0',
        state: 'closed',
        createdAt: testCreatedAt,
      );

      // Assert
      expect(milestone.isOpen, false);
      expect(milestone.isClosed, true);
    });

    test('toString should return formatted milestone string', () {
      // Arrange
      final milestone = Milestone(
        number: 1,
        title: 'v1.0.0',
        state: 'open',
        createdAt: testCreatedAt,
      );

      // Assert
      expect(milestone.toString(), 'Milestone(#1: v1.0.0)');
    });
  });

  group('User Model', () {
    test('should serialize User to JSON', () {
      // Arrange
      final user = User(
        login: 'testuser',
        id: 12345,
        avatarUrl: 'https://avatars.githubusercontent.com/u/12345',
        htmlUrl: 'https://github.com/testuser',
        name: 'Test User',
        email: 'test@example.com',
        company: 'Test Corp',
        blog: 'https://testuser.dev',
        location: 'San Francisco',
        bio: 'A test user',
      );

      // Act
      final json = user.toJson();

      // Assert
      expect(json['login'], 'testuser');
      expect(json['id'], 12345);
      expect(
        json['avatar_url'],
        'https://avatars.githubusercontent.com/u/12345',
      );
      expect(json['html_url'], 'https://github.com/testuser');
      expect(json['name'], 'Test User');
      expect(json['email'], 'test@example.com');
    });

    test('should deserialize User from JSON', () {
      // Arrange
      final json = <String, dynamic>{
        'login': 'testuser',
        'id': 12345,
        'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
        'html_url': 'https://github.com/testuser',
        'name': 'Test User',
        'email': 'test@example.com',
        'company': 'Test Corp',
        'blog': 'https://testuser.dev',
        'location': 'San Francisco',
        'bio': 'A test user',
      };

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.login, 'testuser');
      expect(user.id, 12345);
      expect(user.avatarUrl, 'https://avatars.githubusercontent.com/u/12345');
      expect(user.htmlUrl, 'https://github.com/testuser');
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
    });

    test('displayName should return name when available', () {
      // Arrange
      final user = User(login: 'testuser', name: 'Test User');

      // Assert
      expect(user.displayName, 'Test User');
    });

    test('displayName should return login when name is null', () {
      // Arrange
      final user = User(login: 'testuser', name: null);

      // Assert
      expect(user.displayName, 'testuser');
    });

    test('toString should return login', () {
      // Arrange
      final user = User(login: 'testuser');

      // Assert
      expect(user.toString(), 'User(testuser)');
    });

    test('should handle minimal User with only login', () {
      // Arrange
      final json = <String, dynamic>{'login': 'testuser'};

      // Act
      final user = User.fromJson(json);

      // Assert
      expect(user.login, 'testuser');
      expect(user.id, isNull);
      expect(user.avatarUrl, isNull);
      expect(user.name, isNull);
      expect(user.displayName, 'testuser');
    });
  });
}
