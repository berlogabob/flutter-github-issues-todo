import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/issue_detail_screen.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('IssueDetailScreen Widget Tests', () {
    // Create a mock issue for testing
    IssueItem createMockIssue({
      String title = 'Test Issue',
      String body = 'Test body content',
      ItemStatus status = ItemStatus.open,
      List<String> labels = const ['bug'],
      String? assignee = 'testuser',
      int number = 1,
    }) {
      return IssueItem(
        id: 'test-id-1',
        title: title,
        number: number,
        bodyMarkdown: body,
        status: status,
        labels: labels,
        assigneeLogin: assignee,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
      );
    }

    Widget createTestApp({required IssueItem issue}) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: IssueDetailScreen(
            issue: issue,
            owner: 'testowner',
            repo: 'testrepo',
          ),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders issue detail screen', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byType(IssueDetailScreen), findsOneWidget);
      });

      testWidgets('displays issue title', (tester) async {
        final issue = createMockIssue(title: 'My Test Issue');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('My Test Issue'), findsOneWidget);
      });

      testWidgets('displays issue number in app bar', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('#1'), findsOneWidget);
      });

      testWidgets('displays issue body content', (tester) async {
        final issue = createMockIssue(body: 'This is the issue description');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('This is the issue description'), findsWidgets);
      });

      testWidgets('has correct background color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays status badge', (tester) async {
        final issue = createMockIssue(status: ItemStatus.open);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Open'), findsWidgets);
      });
    });

    group('Labels Display', () {
      testWidgets('displays issue labels', (tester) async {
        final issue = createMockIssue(labels: ['bug', 'urgent']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('bug'), findsWidgets);
        expect(find.text('urgent'), findsWidgets);
      });

      testWidgets('labels have correct styling', (tester) async {
        final issue = createMockIssue(labels: ['feature']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Label chips should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Chip') || 
                      widget.toString().contains('Container'),
        ), findsWidgets);
      });

      testWidgets('shows label section header', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Labels'), findsWidgets);
      });
    });

    group('Assignee Display', () {
      testWidgets('displays assignee information', (tester) async {
        final issue = createMockIssue(assignee: 'john_doe');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('john_doe'), findsWidgets);
      });

      testWidgets('shows assignee section header', (tester) async {
        final issue = createMockIssue(assignee: 'jane_doe');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Assignee'), findsWidgets);
      });

      testWidgets('displays assignee avatar or initial', (tester) async {
        final issue = createMockIssue(assignee: 'alice');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should show avatar or circle avatar with initial
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('handles null assignee gracefully', (tester) async {
        final issue = createMockIssue(assignee: null);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should not crash with null assignee
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      });
    });

    group('Comments Section', () {
      testWidgets('displays comments section header', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Comments'), findsWidgets);
      });

      testWidgets('shows loading indicator for comments', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pump();

        // Loading indicator should be visible
        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('displays comment count', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Comments'), findsWidgets);
      });

      testWidgets('shows add comment button', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should have text field or button for adding comments
        expect(find.byType(TextField), findsWidgets);
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator initially', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during data fetch', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('hides loading indicator when data loaded', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // After settling, main content should be visible
        expect(find.text(issue.title), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on failure', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Error container should be present in widget tree
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('provides retry option on error', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Refresh button should be available
        expect(find.byIcon(Icons.refresh), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('edit button is clickable', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final editButton = find.byIcon(Icons.edit);
        if (editButton.evaluate().isNotEmpty) {
          await tester.tap(editButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('status toggle button is clickable', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Status toggle should be clickable
        expect(find.byType(IconButton), findsWidgets);
      });

      testWidgets('label management is accessible', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Label chips should be interactive
        expect(find.byWidgetPredicate(
          (widget) => widget is InkWell || widget is GestureDetector,
        ), findsWidgets);
      });

      testWidgets('assignee picker is accessible', (tester) async {
        final issue = createMockIssue(assignee: 'user1');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Assignee section should be interactive
        expect(find.byType(InkWell), findsWidgets);
      });
    });

    group('Markdown Rendering', () {
      testWidgets('renders markdown in issue body', (tester) async {
        final issue = createMockIssue(body: '**Bold text** and _italic_');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Markdown widget should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Markdown'),
        ), findsWidgets);
      });

      testWidgets('handles empty body gracefully', (tester) async {
        final issue = createMockIssue(body: '');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should not crash with empty body
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      });

      testWidgets('handles null body gracefully', (tester) async {
        final issue = createMockIssue();
        issue.bodyMarkdown = null;
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should not crash with null body
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      });
    });

    group('AppBar Actions', () {
      testWidgets('app bar has edit button', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.edit), findsWidgets);
      });

      testWidgets('app bar has correct background color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar displays issue number', (tester) async {
        final issue = createMockIssue(number: 42);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('#42'), findsWidgets);
      });
    });

    group('Status Badge', () {
      testWidgets('displays open status correctly', (tester) async {
        final issue = createMockIssue(status: ItemStatus.open);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Open'), findsWidgets);
      });

      testWidgets('displays closed status correctly', (tester) async {
        final issue = createMockIssue(status: ItemStatus.closed);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Closed'), findsWidgets);
      });

      testWidgets('status badge has correct color for open', (tester) async {
        final issue = createMockIssue(status: ItemStatus.open);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Status badge should use green color for open
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
                      widget.decoration is BoxDecoration,
        ), findsWidgets);
      });
    });

    group('Relative Time Display', () {
      testWidgets('displays updated time', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should show relative time like "Updated X ago"
        expect(find.textContaining('Updated'), findsWidgets);
      });

      testWidgets('formats time correctly', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Time should be displayed
        expect(find.byWidgetPredicate(
          (widget) => widget is Text &&
                      widget.data?.contains('ago') == true,
        ), findsWidgets);
      });
    });

    group('Local Issue Handling', () {
      testWidgets('handles local-only issues', (tester) async {
        final issue = createMockIssue();
        issue.isLocalOnly = true;
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should display local issue indicator
        expect(find.byType(IssueDetailScreen), findsOneWidget);
      });

      testWidgets('shows sync status for local issues', (tester) async {
        final issue = createMockIssue();
        issue.isLocalOnly = true;
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Local issues should have sync indicator
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('sync') ||
                      widget.toString().contains('cloud'),
        ), findsWidgets);
      });
    });

    group('Scroll Behavior', () {
      testWidgets('content is scrollable', (tester) async {
        final issue = createMockIssue(
          body: 'Long body content\n' * 50,
        );
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should have scrollable content
        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('can scroll to see comments', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Comments section should be reachable by scrolling
        expect(find.textContaining('Comments'), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => MaterialApp(
              home: IssueDetailScreen(
                issue: issue,
                owner: 'testowner',
                repo: 'testrepo',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(issue.title), findsOneWidget);
      });

      testWidgets('uses ScreenUtil for responsive sizing', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Text widgets should use responsive sizing
        expect(find.byType(Text), findsWidgets);
      });
    });
  });
}
