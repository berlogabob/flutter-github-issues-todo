import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/github_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GitHubRepository Model', () {
    // Test data
    final testCreatedAt = DateTime(2024, 1, 1, 10, 0, 0);
    final testUpdatedAt = DateTime(2024, 1, 15, 14, 30, 0);
    final testPushedAt = DateTime(2024, 1, 14, 9, 0, 0);

    final testOwner = User(
      login: 'flutter',
      id: 12345,
      avatarUrl: 'https://avatars.githubusercontent.com/u/12345',
      htmlUrl: 'https://github.com/flutter',
      name: 'Flutter',
    );

    final testRepository = GitHubRepository(
      id: 123456789,
      nodeId: 'R_kgDOGhJxYw',
      name: 'flutter',
      fullName: 'flutter/flutter',
      owner: testOwner,
      private: false,
      htmlUrl: 'https://github.com/flutter/flutter',
      description:
          'Flutter makes it easy and fast to build beautiful apps for mobile and beyond',
      fork: false,
      createdAt: testCreatedAt,
      updatedAt: testUpdatedAt,
      pushedAt: testPushedAt,
      gitUrl: 'git://github.com/flutter/flutter.git',
      sshUrl: 'git@github.com:flutter/flutter.git',
      cloneUrl: 'https://github.com/flutter/flutter.git',
      defaultBranch: 'main',
      openIssuesCount: 1500,
      stargazersCount: 150000,
      watchersCount: 3000,
      forksCount: 25000,
      language: 'Dart',
      archived: false,
      disabled: false,
      hasIssues: true,
      hasProjects: true,
      hasWiki: true,
      hasPages: false,
      hasDownloads: true,
      homepage: 'https://flutter.dev',
    );

    group('JSON Serialization', () {
      test('should serialize GitHubRepository to JSON', () {
        // Arrange
        final repo = testRepository;

        // Act
        final json = repo.toJson();

        // Assert
        expect(json['id'], 123456789);
        expect(json['node_id'], 'R_kgDOGhJxYw');
        expect(json['name'], 'flutter');
        expect(json['full_name'], 'flutter/flutter');
        expect(json['private'], false);
        expect(json['html_url'], 'https://github.com/flutter/flutter');
        expect(json['description'], contains('Flutter makes it easy'));
        expect(json['fork'], false);
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['updated_at'], testUpdatedAt.toIso8601String());
        expect(json['pushed_at'], testPushedAt.toIso8601String());
        expect(json['git_url'], 'git://github.com/flutter/flutter.git');
        expect(json['ssh_url'], 'git@github.com:flutter/flutter.git');
        expect(json['clone_url'], 'https://github.com/flutter/flutter.git');
        expect(json['default_branch'], 'main');
        expect(json['open_issues_count'], 1500);
        expect(json['stargazers_count'], 150000);
        expect(json['watchers_count'], 3000);
        expect(json['forks_count'], 25000);
        expect(json['language'], 'Dart');
        expect(json['archived'], false);
        expect(json['disabled'], false);
        expect(json['has_issues'], true);
        expect(json['has_projects'], true);
        expect(json['has_wiki'], true);
        expect(json['has_pages'], false);
        expect(json['has_downloads'], true);
        expect(json['homepage'], 'https://flutter.dev');
      });

      test('should deserialize GitHubRepository from JSON', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 123456789,
          'node_id': 'R_kgDOGhJxYw',
          'name': 'flutter',
          'full_name': 'flutter/flutter',
          'owner': {
            'login': 'flutter',
            'id': 12345,
            'avatar_url': 'https://avatars.githubusercontent.com/u/12345',
            'html_url': 'https://github.com/flutter',
          },
          'private': false,
          'html_url': 'https://github.com/flutter/flutter',
          'description': 'Flutter SDK',
          'fork': false,
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
          'pushed_at': testPushedAt.toIso8601String(),
          'git_url': 'git://github.com/flutter/flutter.git',
          'ssh_url': 'git@github.com:flutter/flutter.git',
          'clone_url': 'https://github.com/flutter/flutter.git',
          'default_branch': 'main',
          'open_issues_count': 1500,
          'stargazers_count': 150000,
          'watchers_count': 3000,
          'forks_count': 25000,
          'language': 'Dart',
          'archived': false,
          'disabled': false,
          'has_issues': true,
          'has_projects': true,
          'has_wiki': true,
          'has_pages': false,
          'has_downloads': true,
          'homepage': 'https://flutter.dev',
        };

        // Act
        final repo = GitHubRepository.fromJson(json);

        // Assert
        expect(repo.id, 123456789);
        expect(repo.nodeId, 'R_kgDOGhJxYw');
        expect(repo.name, 'flutter');
        expect(repo.fullName, 'flutter/flutter');
        expect(repo.owner?.login, 'flutter');
        expect(repo.private, false);
        expect(repo.htmlUrl, 'https://github.com/flutter/flutter');
        expect(repo.description, 'Flutter SDK');
        expect(repo.fork, false);
        expect(repo.createdAt, testCreatedAt);
        expect(repo.updatedAt, testUpdatedAt);
        expect(repo.pushedAt, testPushedAt);
        expect(repo.defaultBranch, 'main');
        expect(repo.openIssuesCount, 1500);
        expect(repo.stargazersCount, 150000);
        expect(repo.language, 'Dart');
        expect(repo.archived, false);
        expect(repo.disabled, false);
        expect(repo.hasIssues, true);
      });

      test('should handle null optional fields', () {
        // Arrange
        final json = <String, dynamic>{
          'id': 1,
          'node_id': 'R_1',
          'name': 'test-repo',
          'full_name': 'user/test-repo',
          'owner': {'login': 'user'},
          'private': false,
          'html_url': 'https://github.com/user/test-repo',
          'description': null,
          'fork': false,
          'created_at': testCreatedAt.toIso8601String(),
          'updated_at': testUpdatedAt.toIso8601String(),
          'pushed_at': null,
          'git_url': 'git://github.com/user/test-repo.git',
          'ssh_url': 'git@github.com:user/test-repo.git',
          'clone_url': 'https://github.com/user/test-repo.git',
          'default_branch': 'main',
          'open_issues_count': null,
          'stargazers_count': null,
          'watchers_count': null,
          'forks_count': null,
          'language': null,
          'archived': false,
          'disabled': false,
          'has_issues': true,
          'has_projects': true,
          'has_wiki': true,
          'has_pages': false,
          'has_downloads': true,
          'homepage': null,
        };

        // Act
        final repo = GitHubRepository.fromJson(json);

        // Assert
        expect(repo.description, isNull);
        expect(repo.pushedAt, isNull);
        expect(repo.openIssuesCount, isNull);
        expect(repo.stargazersCount, isNull);
        expect(repo.language, isNull);
        expect(repo.homepage, isNull);
      });

      test('should serialize and deserialize back to same values', () {
        // Arrange
        final original = testRepository;

        // Act
        final json = original.toJson();
        final deserialized = GitHubRepository.fromJson(json);

        // Assert
        expect(deserialized.id, original.id);
        expect(deserialized.name, original.name);
        expect(deserialized.fullName, original.fullName);
        expect(deserialized.private, original.private);
        expect(deserialized.archived, original.archived);
        expect(deserialized.hasIssues, original.hasIssues);
      });
    });

    group('copyWith Method', () {
      test('should create a copy with all fields unchanged', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.fullName, original.fullName);
        expect(copy.owner, original.owner);
        expect(copy.private, original.private);
        expect(copy.description, original.description);
        expect(copy.fork, original.fork);
        expect(copy.createdAt, original.createdAt);
        expect(copy.updatedAt, original.updatedAt);
        expect(copy.pushedAt, original.pushedAt);
        expect(copy.defaultBranch, original.defaultBranch);
        expect(copy.archived, original.archived);
        expect(copy.disabled, original.disabled);
        expect(copy.hasIssues, original.hasIssues);
        expect(copy.language, original.language);
        expect(copy, isNot(same(original)));
      });

      test('should update name field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(name: 'flutter-new');

        // Assert
        expect(copy.name, 'flutter-new');
        expect(copy.fullName, original.fullName);
      });

      test('should update fullName field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(fullName: 'flutter/flutter-new');

        // Assert
        expect(copy.fullName, 'flutter/flutter-new');
      });

      test('should update description field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(description: 'Updated description');

        // Assert
        expect(copy.description, 'Updated description');
      });

      test('should update openIssuesCount field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(openIssuesCount: 2000);

        // Assert
        expect(copy.openIssuesCount, 2000);
      });

      test('should update stargazersCount field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(stargazersCount: 200000);

        // Assert
        expect(copy.stargazersCount, 200000);
      });

      test('should update language field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(language: 'Kotlin');

        // Assert
        expect(copy.language, 'Kotlin');
      });

      test('should update archived field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(archived: true);

        // Assert
        expect(copy.archived, true);
        expect(copy.isArchived, true);
      });

      test('should update disabled field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(disabled: true);

        // Assert
        expect(copy.disabled, true);
        expect(copy.isDisabled, true);
      });

      test('should update hasIssues field', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(hasIssues: false);

        // Assert
        expect(copy.hasIssues, false);
      });

      test('should update owner field', () {
        // Arrange
        final original = testRepository;
        final newOwner = User(login: 'newowner');

        // Act
        final copy = original.copyWith(owner: newOwner);

        // Assert
        expect(copy.owner?.login, 'newowner');
        expect(copy.ownerLogin, 'newowner');
      });

      test('should update multiple fields at once', () {
        // Arrange
        final original = testRepository;

        // Act
        final copy = original.copyWith(
          name: 'new-name',
          description: 'New description',
          archived: true,
          openIssuesCount: 500,
        );

        // Assert
        expect(copy.name, 'new-name');
        expect(copy.description, 'New description');
        expect(copy.archived, true);
        expect(copy.openIssuesCount, 500);
        expect(copy.id, original.id);
        expect(copy.fullName, original.fullName);
      });
    });

    group('Getters', () {
      test('ownerLogin should return owner login when owner exists', () {
        // Arrange
        final repo = testRepository;

        // Assert
        expect(repo.ownerLogin, 'flutter');
      });

      test('ownerLogin should extract from fullName when owner is null', () {
        // Arrange
        final repo = GitHubRepository(
          id: 1,
          nodeId: 'R_1',
          name: 'test',
          fullName: 'user/test',
          owner: null,
          private: false,
          htmlUrl: 'https://github.com/user/test',
          fork: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          gitUrl: 'git://github.com/user/test.git',
          sshUrl: 'git@github.com:user/test.git',
          cloneUrl: 'https://github.com/user/test.git',
          defaultBranch: 'main',
          archived: false,
          disabled: false,
          hasIssues: true,
          hasProjects: true,
          hasWiki: true,
          hasPages: false,
          hasDownloads: true,
        );

        // Assert
        expect(repo.ownerLogin, 'user');
      });

      test('isArchived should return true when archived is true', () {
        // Arrange
        final repo = testRepository.copyWith(archived: true);

        // Assert
        expect(repo.isArchived, true);
      });

      test('isArchived should return false when archived is false', () {
        // Arrange
        final repo = testRepository.copyWith(archived: false);

        // Assert
        expect(repo.isArchived, false);
      });

      test('isDisabled should return true when disabled is true', () {
        // Arrange
        final repo = testRepository.copyWith(disabled: true);

        // Assert
        expect(repo.isDisabled, true);
      });

      test('isDisabled should return false when disabled is false', () {
        // Arrange
        final repo = testRepository.copyWith(disabled: false);

        // Assert
        expect(repo.isDisabled, false);
      });

      test('displayName should return fullName', () {
        // Arrange
        final repo = testRepository;

        // Assert
        expect(repo.displayName, 'flutter/flutter');
      });
    });

    group('Equality', () {
      test('should be equal when id, name, and fullName match', () {
        // Arrange
        final repo1 = GitHubRepository(
          id: 123,
          nodeId: 'R_1',
          name: 'test',
          fullName: 'user/test',
          owner: null,
          private: false,
          htmlUrl: 'https://github.com/user/test',
          fork: false,
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          gitUrl: 'git://github.com/user/test.git',
          sshUrl: 'git@github.com:user/test.git',
          cloneUrl: 'https://github.com/user/test.git',
          defaultBranch: 'main',
          archived: false,
          disabled: false,
          hasIssues: true,
          hasProjects: true,
          hasWiki: true,
          hasPages: false,
          hasDownloads: true,
        );
        final repo2 = GitHubRepository(
          id: 123,
          nodeId: 'R_2', // Different nodeId
          name: 'test',
          fullName: 'user/test',
          owner: null,
          private: true, // Different private
          htmlUrl: 'https://github.com/user/test',
          fork: false,
          createdAt: DateTime(2025, 1, 1), // Different date
          updatedAt: testUpdatedAt,
          gitUrl: 'git://github.com/user/test.git',
          sshUrl: 'git@github.com:user/test.git',
          cloneUrl: 'https://github.com/user/test.git',
          defaultBranch: 'main',
          archived: false,
          disabled: false,
          hasIssues: true,
          hasProjects: true,
          hasWiki: true,
          hasPages: false,
          hasDownloads: true,
        );

        // Assert
        expect(repo1, equals(repo2));
      });

      test('should not be equal when id differs', () {
        // Arrange
        final repo1 = testRepository;
        final repo2 = testRepository.copyWith(id: 999);

        // Assert
        expect(repo1, isNot(equals(repo2)));
      });

      test('should not be equal when name differs', () {
        // Arrange
        final repo1 = testRepository;
        final repo2 = testRepository.copyWith(name: 'different');

        // Assert
        expect(repo1, isNot(equals(repo2)));
      });

      test('should not be equal when fullName differs', () {
        // Arrange
        final repo1 = testRepository;
        final repo2 = testRepository.copyWith(fullName: 'other/repo');

        // Assert
        expect(repo1, isNot(equals(repo2)));
      });

      test('should be identical to itself', () {
        // Arrange
        final repo = testRepository;

        // Assert
        expect(repo, equals(repo));
      });

      test('should not be equal to non-GitHubRepository object', () {
        // Arrange
        final repo = testRepository;

        // Assert
        expect(repo, isNot(equals('not a repo')));
        expect(repo, isNot(equals(42)));
        expect(repo, isNot(equals(null)));
      });

      test('hashCode should be consistent', () {
        // Arrange
        final repo1 = testRepository;
        final repo2 = testRepository.copyWith(
          description: 'Different description',
        );

        // Assert
        expect(repo1.hashCode, equals(repo2.hashCode));
      });
    });

    group('toString', () {
      test('should return formatted string with fullName', () {
        // Arrange
        final repo = testRepository;

        // Assert
        expect(repo.toString(), 'GitHubRepository(flutter/flutter)');
      });
    });
  });

  group('User Model (in github_repository.dart)', () {
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
      expect(json['company'], 'Test Corp');
      expect(json['blog'], 'https://testuser.dev');
      expect(json['location'], 'San Francisco');
      expect(json['bio'], 'A test user');
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
