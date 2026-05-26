import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/services/local_storage_service.dart';

import '../support/test_support.dart';

void main() {
  group('LocalStorageService offline-first persistence', () {
    late Directory vaultDir;

    setUp(() async {
      await TestHarness.shared.install();
      vaultDir = await Directory.systemTemp.createTemp(
        'gitdoit_local_storage_test_',
      );
      TestHarness.shared.secureStorage.write('vault_folder', vaultDir.path);
    });

    tearDown(() async {
      if (await vaultDir.exists()) {
        await vaultDir.delete(recursive: true);
      }
    });

    test('round-trips local issue markdown and frontmatter fields', () async {
      final service = LocalStorageService();
      final createdAt = DateTime.utc(2026, 5, 1, 10);
      final updatedAt = DateTime.utc(2026, 5, 2, 11, 30);
      final localUpdatedAt = DateTime.utc(2026, 5, 3, 12, 45);
      const markdown = '''
# Keep Markdown

- first item
- second item

```text
literal block
```
''';

      final issue = IssueItem(
        id: 'local_1770000000000',
        title: 'Local markdown issue',
        number: -1770000000000,
        bodyMarkdown: markdown,
        repoFullName: 'octo/offline-repo',
        labels: const ['offline', 'regression'],
        assigneeLogin: 'octocat',
        status: ItemStatus.closed,
        createdAt: createdAt,
        updatedAt: updatedAt,
        localUpdatedAt: localUpdatedAt,
        isLocalOnly: true,
      );

      final saved = await service.saveLocalIssue(issue);
      final loaded = await service.getLocalIssues();

      expect(saved, isTrue);
      expect(loaded, hasLength(1));
      expect(loaded.single.id, issue.id);
      expect(loaded.single.title, issue.title);
      expect(loaded.single.number, issue.number);
      expect(loaded.single.bodyMarkdown, markdown.trim());
      expect(loaded.single.repoFullName, 'octo/offline-repo');
      expect(loaded.single.labels, const ['offline', 'regression']);
      expect(loaded.single.assigneeLogin, 'octocat');
      expect(loaded.single.status, ItemStatus.closed);
      expect(loaded.single.createdAt, createdAt);
      expect(loaded.single.updatedAt, updatedAt);
      expect(loaded.single.localUpdatedAt, localUpdatedAt);
      expect(loaded.single.isLocalOnly, isTrue);
    });

    test('does not write synced issues into vault markdown storage', () async {
      final service = LocalStorageService();
      final syncedIssue = IssueItem(
        id: 'I_123',
        title: 'Synced issue',
        number: 12,
        bodyMarkdown: 'Already on GitHub',
        repoFullName: 'octo/offline-repo',
        isLocalOnly: false,
      );

      final saved = await service.saveLocalIssue(syncedIssue);
      final markdownFiles = vaultDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList();

      expect(saved, isFalse);
      expect(markdownFiles, isEmpty);
    });

    test('replaces stale vault file when local issue title changes', () async {
      final service = LocalStorageService();
      final issue = IssueItem(
        id: 'local_1770000000000',
        title: 'Original Title',
        number: -1770000000000,
        bodyMarkdown: 'Draft body',
        repoFullName: 'octo/offline-repo',
        isLocalOnly: true,
      );

      final renamedIssue = issue.copyWith(title: 'Renamed Title');

      expect(await service.saveLocalIssue(issue), isTrue);
      expect(await service.saveLocalIssue(renamedIssue), isTrue);

      final markdownFiles = vaultDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.md'))
          .toList();

      expect(markdownFiles, hasLength(1));
      expect(markdownFiles.single.path, contains('renamed_title'));
      expect(await service.getLocalIssues(), hasLength(1));
    });

    test('stamps repoFullName when persisting synced issues', () async {
      final service = LocalStorageService();
      final issue = IssueItem(
        id: 'I_123',
        title: 'Synced issue',
        number: 12,
        bodyMarkdown: 'Remote issue body',
      );

      await service.saveSyncedIssues('octo/offline-repo', [issue]);

      final loaded = await service.getSyncedIssues('octo/offline-repo');

      expect(loaded, hasLength(1));
      expect(loaded.single.id, 'I_123');
      expect(loaded.single.repoFullName, 'octo/offline-repo');
      expect(loaded.single.bodyMarkdown, 'Remote issue body');
      expect(loaded.single.isLocalOnly, isFalse);
    });
  });
}
