import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/repo_item.dart';
import 'package:gitdoit/services/github_api_service.dart';
import 'package:gitdoit/widgets/expandable_repo.dart';
import 'package:gitdoit/widgets/issue_card.dart';

void main() {
  group('ExpandableRepo issue state callback', () {
    testWidgets('swipe close notifies parent with closed issue', (
      tester,
    ) async {
      final issue = IssueItem(
        id: 'local-issue-1',
        title: 'Swipe me',
        status: ItemStatus.open,
        isLocalOnly: true,
      );
      final repo = RepoItem(
        id: 'vault',
        title: 'Vault',
        fullName: 'local/vault',
        children: [issue],
      );

      String? callbackRepo;
      IssueItem? callbackIssue;

      await tester.pumpWidget(
        ScreenUtilInit(
          designSize: const Size(360, 690),
          builder: (context, child) => MaterialApp(
            home: Scaffold(
              body: ExpandableRepo(
                repo: repo,
                githubApi: GitHubApiService(),
                onIssueStateChanged: (repoFullName, updatedIssue) {
                  callbackRepo = repoFullName;
                  callbackIssue = updatedIssue;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Swipe me'), findsOneWidget);

      // Directly invoke swipe-left callback to avoid gesture flakiness in nested lists.
      final card = tester.widget<IssueCard>(find.byType(IssueCard).first);
      card.onSwipeLeft?.call();
      await tester.pumpAndSettle();

      expect(callbackRepo, equals('local/vault'));
      expect(callbackIssue, isNotNull);
      expect(callbackIssue!.id, equals('local-issue-1'));
      expect(callbackIssue!.status, equals(ItemStatus.closed));
    });
  });
}
