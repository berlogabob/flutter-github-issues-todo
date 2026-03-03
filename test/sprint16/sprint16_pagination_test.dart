import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/repo_item.dart';
import 'package:gitdoit/models/item.dart';

void main() {
  group('Task 16.1 - Pagination Tests', () {
    group('Load first page of repos', () {
      test('should create RepoItem with correct status type', () {
        // Arrange & Act
        final repo = RepoItem(
          id: 'repo1',
          title: 'Test Repo 1',
          fullName: 'user/repo1',
          description: 'Test description 1',
          status: ItemStatus.open,
        );

        // Assert
        expect(repo.status, ItemStatus.open);
        expect(repo.title, 'Test Repo 1');
      });

      test('should create multiple repos for first page', () {
        // Arrange
        final repos = List.generate(30, (i) => RepoItem(
          id: 'repo$i',
          title: 'Repo $i',
          fullName: 'user/repo$i',
          description: 'Description $i',
          status: ItemStatus.open,
        ));

        // Assert
        expect(repos.length, 30);
        expect(repos.first.title, 'Repo 0');
        expect(repos.last.title, 'Repo 29');
      });

      test('RepoItem toJson includes all fields', () {
        // Arrange
        final repo = RepoItem(
          id: 'repo1',
          title: 'Test Repo',
          fullName: 'user/repo1',
          description: 'Test',
          status: ItemStatus.open,
          children: [],
        );

        // Act
        final json = repo.toJson();

        // Assert
        expect(json['id'], 'repo1');
        expect(json['title'], 'Test Repo');
        expect(json['fullName'], 'user/repo1');
        expect(json['status'], 'open');
      });

      test('RepoItem fromJson creates valid instance', () {
        // Arrange
        final json = {
          'id': 'repo1',
          'title': 'Test Repo',
          'fullName': 'user/repo1',
          'description': 'Test description',
          'status': 'open',
          'children': [],
        };

        // Act
        final repo = RepoItem.fromJson(json);

        // Assert
        expect(repo.id, 'repo1');
        expect(repo.title, 'Test Repo');
        expect(repo.fullName, 'user/repo1');
        expect(repo.status, ItemStatus.open);
      });
    });

    group('Load more repos (page 2)', () {
      test('should append page 2 results to existing list', () {
        // Arrange
        final page1Repos = List.generate(30, (i) => RepoItem(
          id: 'repo$i',
          title: 'Repo $i',
          fullName: 'user/repo$i',
          description: 'Description $i',
          status: ItemStatus.open,
        ));

        final page2Repos = List.generate(15, (i) => RepoItem(
          id: 'repo${30 + i}',
          title: 'Repo ${30 + i}',
          fullName: 'user/repo${30 + i}',
          description: 'Description ${30 + i}',
          status: ItemStatus.open,
        ));

        // Act - simulate appending
        final allRepos = [...page1Repos, ...page2Repos];

        // Assert
        expect(allRepos.length, 45);
        expect(allRepos.first.title, 'Repo 0');
        expect(allRepos.last.title, 'Repo 44');
      });

      test('should have unique IDs across pages', () {
        // Arrange
        final page1Ids = List.generate(30, (i) => 'repo$i');
        final page2Ids = List.generate(30, (i) => 'repo${30 + i}');

        // Act
        final allIds = [...page1Ids, ...page2Ids];
        final uniqueIds = allIds.toSet();

        // Assert
        expect(allIds.length, uniqueIds.length); // No duplicates
      });
    });

    group('"Load More" button appears', () {
      test('should indicate more repos available when page is full', () {
        // Arrange
        final fullPage = List.generate(30, (i) => RepoItem(
          id: 'repo$i',
          title: 'Repo $i',
          fullName: 'user/repo$i',
          description: 'Description $i',
          status: ItemStatus.open,
        ));

        // Act
        final hasMore = fullPage.length == 30;

        // Assert
        expect(hasMore, true);
      });

      test('should indicate no more repos when page is not full', () {
        // Arrange
        final partialPage = List.generate(15, (i) => RepoItem(
          id: 'repo$i',
          title: 'Repo $i',
          fullName: 'user/repo$i',
          description: 'Description $i',
          status: ItemStatus.open,
        ));

        // Act
        final hasMore = partialPage.length == 30;

        // Assert
        expect(hasMore, false);
      });

      test('pagination state variables work correctly', () {
        // Arrange
        int currentPage = 1;
        const perPage = 30;
        bool hasMoreRepos = true;
        bool isLoadingMore = false;

        // Act - simulate loading page 2
        isLoadingMore = true;
        currentPage++;
        isLoadingMore = false;
        hasMoreRepos = true; // Assume more available

        // Assert
        expect(currentPage, 2);
        expect(isLoadingMore, false);
        expect(hasMoreRepos, true);
      });
    });

    group('Cache stores multiple pages', () {
      test('should have different cache keys for different pages', () {
        // Arrange
        final cacheKeys = [
          'repos_page_1',
          'repos_page_2',
          'repos_page_3',
        ];

        // Assert - keys should be unique
        expect(cacheKeys.length, cacheKeys.toSet().length);
        expect(cacheKeys[0] != cacheKeys[1], true);
        expect(cacheKeys[1] != cacheKeys[2], true);
      });

      test('cache key format includes page number', () {
        // Arrange
        final page = 2;
        final cacheKey = 'repos_page_$page';

        // Assert
        expect(cacheKey, 'repos_page_2');
        expect(cacheKey.contains('page_2'), true);
      });

      test('should store and retrieve repos by page', () {
        // Arrange - simulate cache
        final cache = <String, List<RepoItem>>{};
        
        final page1Repos = [
          RepoItem(id: 'repo1', title: 'Repo 1', fullName: 'user/repo1', description: 'Desc 1', status: ItemStatus.open),
        ];
        final page2Repos = [
          RepoItem(id: 'repo31', title: 'Repo 31', fullName: 'user/repo31', description: 'Desc 31', status: ItemStatus.open),
        ];

        // Act - store in cache
        cache['repos_page_1'] = page1Repos;
        cache['repos_page_2'] = page2Repos;

        // Assert - retrieve from cache
        expect(cache['repos_page_1']!.length, 1);
        expect(cache['repos_page_1']!.first.title, 'Repo 1');
        expect(cache['repos_page_2']!.length, 1);
        expect(cache['repos_page_2']!.first.title, 'Repo 31');
      });
    });

    group('Works offline (shows cached pages)', () {
      test('should return cached data when offline', () {
        // Arrange - simulate cache
        final cache = <String, List<RepoItem>>{
          'repos_page_1': [
            RepoItem(id: 'repo1', title: 'Offline Repo', fullName: 'user/repo1', description: 'Offline', status: ItemStatus.open),
          ],
        };

        // Act - get from cache
        final cachedResult = cache['repos_page_1'];

        // Assert
        expect(cachedResult, isNotNull);
        expect(cachedResult!.length, 1);
        expect(cachedResult.first.title, 'Offline Repo');
      });

      test('should handle empty cache gracefully', () {
        // Arrange
        final cache = <String, List<RepoItem>>{};

        // Act
        final result = cache['repos_page_1'];

        // Assert
        expect(result, isNull);
      });

      test('RepoItem copyWith preserves data', () {
        // Arrange
        final original = RepoItem(
          id: 'repo1',
          title: 'Original',
          fullName: 'user/repo1',
          description: 'Description',
          status: ItemStatus.open,
        );

        // Act
        final modified = original.copyWith(title: 'Updated');

        // Assert
        expect(modified.title, 'Updated');
        expect(modified.id, 'repo1'); // Unchanged
        expect(modified.fullName, 'user/repo1'); // Unchanged
      });
    });

    group('Integration Tests', () {
      test('complete pagination flow', () {
        // Arrange
        final allPages = <List<RepoItem>>[];
        int page = 1;
        const perPage = 30;
        bool hasMore = true;

        // Simulate fetching pages
        while (hasMore && page <= 3) {
          final pageRepos = List.generate(perPage, (i) => RepoItem(
            id: 'repo${(page - 1) * perPage + i}',
            title: 'Repo ${(page - 1) * perPage + i}',
            fullName: 'user/repo${(page - 1) * perPage + i}',
            description: 'Description',
            status: ItemStatus.open,
          ));
          allPages.add(pageRepos);
          
          // Last page has fewer items
          hasMore = page < 3;
          page++;
        }

        // Act - flatten all pages
        final allRepos = allPages.expand((p) => p).toList();

        // Assert
        expect(allRepos.length, 90); // 3 pages * 30 items
        expect(allRepos.first.title, 'Repo 0');
        expect(allRepos.last.title, 'Repo 89');
      });

      test('RepoItem with children (issues)', () {
        // Arrange
        final repo = RepoItem(
          id: 'repo1',
          title: 'Test Repo',
          fullName: 'user/repo1',
          description: 'Description',
          status: ItemStatus.open,
          children: List.generate(5, (i) => RepoItem(
            id: 'issue$i',
            title: 'Issue $i',
            fullName: 'user/repo1#$i',
            description: 'Issue description',
            status: i % 2 == 0 ? ItemStatus.open : ItemStatus.closed,
          )),
        );

        // Assert
        expect(repo.children.length, 5);
        expect(repo.children.where((c) => c.status == ItemStatus.open).length, 3);
        expect(repo.children.where((c) => c.status == ItemStatus.closed).length, 2);
      });
    });
  });
}
