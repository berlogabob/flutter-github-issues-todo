import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/utils/repo_config_parser.dart';

void main() {
  group('parseRepositoryInput', () {
    group('plain owner/repo format', () {
      test('parses simple owner/repo', () {
        final result = parseRepositoryInput('flutter/flutter');
        expect(result, isNotNull);
        expect(result!.owner, 'flutter');
        expect(result.repo, 'flutter');
      });

      test('parses owner/repo with spaces', () {
        final result = parseRepositoryInput(
          '  berlogabob  /  flutter-github-issues-todo  ',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'berlogabob');
        expect(result.repo, 'flutter-github-issues-todo');
      });

      test('returns null for single segment', () {
        final result = parseRepositoryInput('onlyowner');
        expect(result, isNull);
      });

      test('returns null for too many segments', () {
        final result = parseRepositoryInput('owner/repo/extra');
        expect(result, isNull);
      });

      test('returns null for empty string', () {
        final result = parseRepositoryInput('');
        expect(result, isNull);
      });
    });

    group('HTTPS URL format', () {
      test('parses standard GitHub URL', () {
        final result = parseRepositoryInput(
          'https://github.com/flutter/flutter',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'flutter');
        expect(result.repo, 'flutter');
      });

      test('parses HTTP GitHub URL', () {
        final result = parseRepositoryInput(
          'http://github.com/berlogabob/my-app',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'berlogabob');
        expect(result.repo, 'my-app');
      });

      test('parses URL with trailing path', () {
        final result = parseRepositoryInput(
          'https://github.com/flutter/flutter/issues/123',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'flutter');
        expect(result.repo, 'flutter');
      });

      test('parses URL with .git extension', () {
        final result = parseRepositoryInput(
          'https://github.com/flutter/flutter.git',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'flutter');
        expect(result.repo, 'flutter');
      });

      test('returns null for non-GitHub URL', () {
        final result = parseRepositoryInput('https://gitlab.com/owner/repo');
        expect(result, isNull);
      });

      test('returns null for URL with insufficient path', () {
        final result = parseRepositoryInput('https://github.com/onlyowner');
        expect(result, isNull);
      });
    });

    group('SSH URL format', () {
      test('parses SSH URL with .git', () {
        final result = parseRepositoryInput(
          'git@github.com:flutter/flutter.git',
        );
        expect(result, isNotNull);
        expect(result!.owner, 'flutter');
        expect(result.repo, 'flutter');
      });

      test('parses SSH URL without .git', () {
        final result = parseRepositoryInput('git@github.com:berlogabob/my-app');
        expect(result, isNotNull);
        expect(result!.owner, 'berlogabob');
        expect(result.repo, 'my-app');
      });

      test('returns null for SSH URL with different host', () {
        final result = parseRepositoryInput('git@gitlab.com:owner/repo.git');
        expect(result, isNull);
      });
    });

    group('RepoOwnerRepo', () {
      test('equality works correctly', () {
        final repo1 = RepoOwnerRepo(owner: 'flutter', repo: 'flutter');
        final repo2 = RepoOwnerRepo(owner: 'flutter', repo: 'flutter');
        final repo3 = RepoOwnerRepo(owner: 'dart', repo: 'lang');

        expect(repo1, equals(repo2));
        expect(repo1, isNot(equals(repo3)));
      });

      test('hashCode works correctly', () {
        final repo1 = RepoOwnerRepo(owner: 'flutter', repo: 'flutter');
        final repo2 = RepoOwnerRepo(owner: 'flutter', repo: 'flutter');

        expect(repo1.hashCode, equals(repo2.hashCode));
      });

      test('toString returns owner/repo format', () {
        final repo = RepoOwnerRepo(
          owner: 'berlogabob',
          repo: 'flutter-github-issues-todo',
        );
        expect(repo.toString(), 'berlogabob/flutter-github-issues-todo');
      });
    });
  });
}
