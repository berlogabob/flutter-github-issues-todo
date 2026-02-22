import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:gitdoit/models/repository_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RepositoryConfig Model', () {
    final testLastSynced = DateTime(2024, 1, 15, 10, 30, 0);

    group('Basic Properties', () {
      test('should create RepositoryConfig with required fields', () {
        // Arrange & Act
        final config = RepositoryConfig(owner: 'flutter', name: 'flutter');

        // Assert
        expect(config.owner, 'flutter');
        expect(config.name, 'flutter');
        expect(config.isEnabled, true);
        expect(config.lastSynced, isNull);
        expect(config.issueCount, isNull);
      });

      test('should create RepositoryConfig with all fields', () {
        // Arrange & Act
        final config = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: false,
          lastSynced: testLastSynced,
          issueCount: 42,
        );

        // Assert
        expect(config.owner, 'flutter');
        expect(config.name, 'flutter');
        expect(config.isEnabled, false);
        expect(config.lastSynced, testLastSynced);
        expect(config.issueCount, 42);
      });
    });

    group('fullName Getter', () {
      test('should return owner/name format', () {
        // Arrange
        final config = RepositoryConfig(owner: 'flutter', name: 'flutter');

        // Assert
        expect(config.fullName, 'flutter/flutter');
      });

      test('should work with different owner and name', () {
        // Arrange
        final config = RepositoryConfig(
          owner: 'google',
          name: 'material-design-icons',
        );

        // Assert
        expect(config.fullName, 'google/material-design-icons');
      });
    });

    group('hasSynced Getter', () {
      test('should return true when lastSynced is not null', () {
        // Arrange
        final config = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          lastSynced: testLastSynced,
        );

        // Assert
        expect(config.hasSynced, true);
      });

      test('should return false when lastSynced is null', () {
        // Arrange
        final config = RepositoryConfig(owner: 'flutter', name: 'flutter');

        // Assert
        expect(config.hasSynced, false);
      });
    });

    group('copyWith Method', () {
      final original = RepositoryConfig(
        owner: 'flutter',
        name: 'flutter',
        isEnabled: true,
        lastSynced: testLastSynced,
        issueCount: 42,
      );

      test('should create a copy with all fields unchanged', () {
        // Act
        final copy = original.copyWith();

        // Assert
        expect(copy.owner, original.owner);
        expect(copy.name, original.name);
        expect(copy.isEnabled, original.isEnabled);
        expect(copy.lastSynced, original.lastSynced);
        expect(copy.issueCount, original.issueCount);
        expect(copy.fullName, original.fullName);
        expect(copy, isNot(same(original)));
      });

      test('should update owner field', () {
        // Act
        final copy = original.copyWith(owner: 'google');

        // Assert
        expect(copy.owner, 'google');
        expect(copy.name, original.name);
        expect(copy.fullName, 'google/flutter');
      });

      test('should update name field', () {
        // Act
        final copy = original.copyWith(name: 'material');

        // Assert
        expect(copy.name, 'material');
        expect(copy.owner, original.owner);
        expect(copy.fullName, 'flutter/material');
      });

      test('should update isEnabled field', () {
        // Act
        final copy = original.copyWith(isEnabled: false);

        // Assert
        expect(copy.isEnabled, false);
      });

      test('should update lastSynced field', () {
        // Arrange
        final newSynced = DateTime(2024, 2, 1);

        // Act
        final copy = original.copyWith(lastSynced: newSynced);

        // Assert
        expect(copy.lastSynced, newSynced);
      });

      test('should update issueCount field', () {
        // Act
        final copy = original.copyWith(issueCount: 100);

        // Assert
        expect(copy.issueCount, 100);
      });

      test('should update multiple fields at once', () {
        // Arrange
        final newSynced = DateTime(2024, 2, 1);

        // Act
        final copy = original.copyWith(
          isEnabled: false,
          issueCount: 100,
          lastSynced: newSynced,
        );

        // Assert
        expect(copy.isEnabled, false);
        expect(copy.issueCount, 100);
        expect(copy.lastSynced, newSynced);
        expect(copy.owner, original.owner);
        expect(copy.name, original.name);
      });

      test('should preserve original value when copying with null', () {
        // Note: The copyWith pattern uses `field ?? this.field`
        // so passing null preserves the original value
        // Act
        final copy = original.copyWith(lastSynced: null, issueCount: null);

        // Assert - values are preserved (this is the copyWith pattern behavior)
        expect(copy.lastSynced, original.lastSynced);
        expect(copy.issueCount, original.issueCount);
      });
    });

    group('Equality', () {
      test('should be equal when owner, name, and isEnabled match', () {
        // Arrange
        final config1 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: true,
        );
        final config2 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: true,
          lastSynced: testLastSynced, // Different lastSynced
        );

        // Assert
        expect(config1, equals(config2));
      });

      test('should not be equal when owner differs', () {
        // Arrange
        final config1 = RepositoryConfig(owner: 'flutter', name: 'flutter');
        final config2 = RepositoryConfig(owner: 'google', name: 'flutter');

        // Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when name differs', () {
        // Arrange
        final config1 = RepositoryConfig(owner: 'flutter', name: 'flutter');
        final config2 = RepositoryConfig(owner: 'flutter', name: 'material');

        // Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should not be equal when isEnabled differs', () {
        // Arrange
        final config1 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: true,
        );
        final config2 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: false,
        );

        // Assert
        expect(config1, isNot(equals(config2)));
      });

      test('should be identical to itself', () {
        // Arrange
        final config = RepositoryConfig(owner: 'flutter', name: 'flutter');

        // Assert
        expect(config, equals(config));
      });

      test('should not be equal to non-RepositoryConfig object', () {
        // Arrange
        final config = RepositoryConfig(owner: 'flutter', name: 'flutter');

        // Assert
        expect(config, isNot(equals('not a config')));
        expect(config, isNot(equals(42)));
        expect(config, isNot(equals(null)));
      });

      test('hashCode should be consistent', () {
        // Arrange
        final config1 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: true,
        );
        final config2 = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: true,
        );

        // Assert
        expect(config1.hashCode, equals(config2.hashCode));
      });
    });

    group('toString', () {
      test(
        'should return formatted string with fullName and enabled state',
        () {
          // Arrange
          final config = RepositoryConfig(
            owner: 'flutter',
            name: 'flutter',
            isEnabled: true,
          );

          // Assert
          expect(
            config.toString(),
            'RepositoryConfig(flutter/flutter, enabled: true)',
          );
        },
      );

      test('should show disabled state correctly', () {
        // Arrange
        final config = RepositoryConfig(
          owner: 'flutter',
          name: 'flutter',
          isEnabled: false,
        );

        // Assert
        expect(
          config.toString(),
          'RepositoryConfig(flutter/flutter, enabled: false)',
        );
      });
    });
  });

  group('MultiRepositoryConfig', () {
    late MultiRepositoryConfig multiConfig;

    setUp(() {
      multiConfig = MultiRepositoryConfig();
    });

    group('Initial State', () {
      test('should start with empty repositories list', () {
        // Assert
        expect(multiConfig.repositories, isEmpty);
        expect(multiConfig.enabledRepositories, isEmpty);
        expect(multiConfig.disabledRepositories, isEmpty);
        expect(multiConfig.hasRepositories, false);
        expect(multiConfig.hasMultipleRepos, false);
        expect(multiConfig.activeRepository, isNull);
      });
    });

    group('addRepository', () {
      test('should add a new repository', () {
        // Act
        multiConfig.addRepository('flutter', 'flutter');

        // Assert
        expect(multiConfig.repositories.length, 1);
        expect(multiConfig.repositories.first.owner, 'flutter');
        expect(multiConfig.repositories.first.name, 'flutter');
        expect(multiConfig.repositories.first.fullName, 'flutter/flutter');
        expect(multiConfig.hasRepositories, true);
      });

      test('should set first repository as active', () {
        // Act
        multiConfig.addRepository('flutter', 'flutter');

        // Assert
        expect(multiConfig.activeRepository, 'flutter/flutter');
      });

      test('should add multiple repositories', () {
        // Act
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');
        multiConfig.addRepository('dart-lang', 'sdk');

        // Assert
        expect(multiConfig.repositories.length, 3);
        expect(multiConfig.hasMultipleRepos, true);
        expect(
          multiConfig.activeRepository,
          'flutter/flutter',
        ); // First one stays active
      });

      test('should notify listeners when adding repository', () {
        // Arrange
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.addRepository('flutter', 'flutter');

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('removeRepository', () {
      test('should remove an existing repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');

        // Act
        multiConfig.removeRepository('flutter/flutter');

        // Assert
        expect(multiConfig.repositories.length, 1);
        expect(multiConfig.repositories.first.fullName, 'google/material');
      });

      test('should set next repository as active when removing active', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');
        expect(multiConfig.activeRepository, 'flutter/flutter');

        // Act
        multiConfig.removeRepository('flutter/flutter');

        // Assert
        expect(multiConfig.activeRepository, 'google/material');
      });

      test('should set active to null when removing last repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        expect(multiConfig.activeRepository, 'flutter/flutter');

        // Act
        multiConfig.removeRepository('flutter/flutter');

        // Assert
        expect(multiConfig.activeRepository, isNull);
        expect(multiConfig.hasRepositories, false);
      });

      test('should not notify when removing non-existent repository', () {
        // Arrange
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.removeRepository('nonexistent/repo');

        // Assert
        expect(notifyCount, 0);
      });

      test('should notify listeners when removing repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.removeRepository('flutter/flutter');

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('toggleRepository', () {
      test('should toggle repository from enabled to disabled', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        expect(multiConfig.repositories.first.isEnabled, true);

        // Act
        multiConfig.toggleRepository('flutter/flutter');

        // Assert
        expect(multiConfig.repositories.first.isEnabled, false);
      });

      test('should toggle repository from disabled to enabled', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.toggleRepository('flutter/flutter');
        expect(multiConfig.repositories.first.isEnabled, false);

        // Act
        multiConfig.toggleRepository('flutter/flutter');

        // Assert
        expect(multiConfig.repositories.first.isEnabled, true);
      });

      test('should move repository between enabled and disabled lists', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        expect(multiConfig.enabledRepositories.length, 1);
        expect(multiConfig.disabledRepositories.length, 0);

        // Act
        multiConfig.toggleRepository('flutter/flutter');

        // Assert
        expect(multiConfig.enabledRepositories.length, 0);
        expect(multiConfig.disabledRepositories.length, 1);
      });

      test('should notify listeners when toggling', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.toggleRepository('flutter/flutter');

        // Assert
        expect(notifyCount, 1);
      });

      test('should not notify when toggling non-existent repository', () {
        // Arrange
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.toggleRepository('nonexistent/repo');

        // Assert
        expect(notifyCount, 0);
      });
    });

    group('setRepositoryEnabled', () {
      test('should enable a disabled repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.toggleRepository('flutter/flutter');
        expect(multiConfig.repositories.first.isEnabled, false);

        // Act
        multiConfig.setRepositoryEnabled('flutter/flutter', true);

        // Assert
        expect(multiConfig.repositories.first.isEnabled, true);
      });

      test('should disable an enabled repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        expect(multiConfig.repositories.first.isEnabled, true);

        // Act
        multiConfig.setRepositoryEnabled('flutter/flutter', false);

        // Assert
        expect(multiConfig.repositories.first.isEnabled, false);
      });

      test('should not notify if state is already the same', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act - already enabled, setting to enabled again
        multiConfig.setRepositoryEnabled('flutter/flutter', true);

        // Assert
        expect(notifyCount, 0);
      });

      test('should notify when state changes', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.setRepositoryEnabled('flutter/flutter', false);

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('updateSyncState', () {
      test('should update lastSynced and issueCount', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        final newSynced = DateTime(2024, 2, 1);

        // Act
        multiConfig.updateSyncState(
          'flutter/flutter',
          lastSynced: newSynced,
          issueCount: 100,
        );

        // Assert
        expect(multiConfig.repositories.first.lastSynced, newSynced);
        expect(multiConfig.repositories.first.issueCount, 100);
      });

      test('should update only lastSynced', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        final newSynced = DateTime(2024, 2, 1);

        // Act
        multiConfig.updateSyncState('flutter/flutter', lastSynced: newSynced);

        // Assert
        expect(multiConfig.repositories.first.lastSynced, newSynced);
        expect(multiConfig.repositories.first.issueCount, isNull);
      });

      test('should update only issueCount', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');

        // Act
        multiConfig.updateSyncState('flutter/flutter', issueCount: 50);

        // Assert
        expect(multiConfig.repositories.first.lastSynced, isNull);
        expect(multiConfig.repositories.first.issueCount, 50);
      });

      test('should notify listeners when updating sync state', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.updateSyncState('flutter/flutter', issueCount: 50);

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('setActiveRepository', () {
      test('should set active repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');

        // Act
        multiConfig.setActiveRepository('google/material');

        // Assert
        expect(multiConfig.activeRepository, 'google/material');
      });

      test('should set active to null', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');

        // Act
        multiConfig.setActiveRepository(null);

        // Assert
        expect(multiConfig.activeRepository, isNull);
      });

      test('should notify listeners when changing active repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.setActiveRepository('google/material');

        // Assert
        expect(notifyCount, 1);
      });

      test('should notify listeners when setting to null', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.setActiveRepository(null);

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('getRepository', () {
      test('should return repository by full name', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');

        // Act
        final repo = multiConfig.getRepository('flutter/flutter');

        // Assert
        expect(repo, isNotNull);
        expect(repo?.owner, 'flutter');
        expect(repo?.name, 'flutter');
      });

      test('should return null for non-existent repository', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');

        // Act
        final repo = multiConfig.getRepository('nonexistent/repo');

        // Assert
        expect(repo, isNull);
      });
    });

    group('clear', () {
      test('should remove all repositories', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');

        // Act
        multiConfig.clear();

        // Assert
        expect(multiConfig.repositories, isEmpty);
        expect(multiConfig.activeRepository, isNull);
        expect(multiConfig.hasRepositories, false);
      });

      test('should notify listeners when clearing', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.clear();

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('loadFromList', () {
      test('should load repositories from list of full names', () {
        // Act
        multiConfig.loadFromList([
          'flutter/flutter',
          'google/material',
          'dart-lang/sdk',
        ]);

        // Assert
        expect(multiConfig.repositories.length, 3);
        expect(multiConfig.repositories[0].fullName, 'flutter/flutter');
        expect(multiConfig.repositories[1].fullName, 'google/material');
        expect(multiConfig.repositories[2].fullName, 'dart-lang/sdk');
        expect(multiConfig.activeRepository, 'flutter/flutter');
      });

      test('should handle empty list', () {
        // Act
        multiConfig.loadFromList([]);

        // Assert
        expect(multiConfig.repositories, isEmpty);
        expect(multiConfig.activeRepository, isNull);
      });

      test('should ignore invalid entries', () {
        // Act
        multiConfig.loadFromList([
          'flutter/flutter',
          'invalid', // Missing slash
          'google/material',
          'another/invalid/entry', // Too many slashes
        ]);

        // Assert
        expect(multiConfig.repositories.length, 2);
        expect(multiConfig.repositories[0].fullName, 'flutter/flutter');
        expect(multiConfig.repositories[1].fullName, 'google/material');
      });

      test('should notify listeners when loading', () {
        // Arrange
        var notifyCount = 0;
        multiConfig.addListener(() => notifyCount++);

        // Act
        multiConfig.loadFromList(['flutter/flutter']);

        // Assert
        expect(notifyCount, 1);
      });
    });

    group('exportToList', () {
      test('should export repositories to list of full names', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');

        // Act
        final list = multiConfig.exportToList();

        // Assert
        expect(list.length, 2);
        expect(list, contains('flutter/flutter'));
        expect(list, contains('google/material'));
      });

      test('should return empty list when no repositories', () {
        // Act
        final list = multiConfig.exportToList();

        // Assert
        expect(list, isEmpty);
      });
    });

    group('enabledRepositories Getter', () {
      test('should return only enabled repositories', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');
        multiConfig.toggleRepository('google/material');

        // Act
        final enabled = multiConfig.enabledRepositories;

        // Assert
        expect(enabled.length, 1);
        expect(enabled.first.fullName, 'flutter/flutter');
      });
    });

    group('disabledRepositories Getter', () {
      test('should return only disabled repositories', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');
        multiConfig.toggleRepository('google/material');

        // Act
        final disabled = multiConfig.disabledRepositories;

        // Assert
        expect(disabled.length, 1);
        expect(disabled.first.fullName, 'google/material');
      });
    });

    group('hasMultipleRepos Getter', () {
      test('should return true when more than one repo is enabled', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.addRepository('google', 'material');

        // Assert
        expect(multiConfig.hasMultipleRepos, true);
      });

      test('should return false when only one repo is enabled', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');

        // Assert
        expect(multiConfig.hasMultipleRepos, false);
      });

      test('should return false when no repos are enabled', () {
        // Arrange
        multiConfig.addRepository('flutter', 'flutter');
        multiConfig.toggleRepository('flutter/flutter');

        // Assert
        expect(multiConfig.hasMultipleRepos, false);
      });
    });
  });
}
