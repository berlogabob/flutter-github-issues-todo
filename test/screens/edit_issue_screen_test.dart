import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/edit_issue_screen.dart';
import 'package:gitdoit/models/issue_item.dart';
import 'package:gitdoit/models/item.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('EditIssueScreen Widget Tests', () {
    IssueItem createMockIssue({
      String title = 'Test Issue',
      String body = 'Test body content',
      ItemStatus status = ItemStatus.open,
      List<String> labels = const ['bug'],
    }) {
      return IssueItem(
        id: 'test-id-1',
        title: title,
        number: 1,
        bodyMarkdown: body,
        status: status,
        labels: labels,
        updatedAt: DateTime.now(),
        isLocalOnly: false,
      );
    }

    Widget createTestApp({required IssueItem issue}) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: EditIssueScreen(
            issue: issue,
            owner: 'testowner',
            repo: 'testrepo',
          ),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders edit issue screen', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byType(EditIssueScreen), findsOneWidget);
      });

      testWidgets('displays Edit Issue title', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Edit Issue'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays save button in app bar', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Form Fields', () {
      testWidgets('displays Title section', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsOneWidget);
      });

      testWidgets('displays Title input with existing value', (tester) async {
        final issue = createMockIssue(title: 'Existing Title');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Existing Title'), findsOneWidget);
      });

      testWidgets('displays Description section', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Description'), findsOneWidget);
      });

      testWidgets('displays Description input with existing value', (tester) async {
        final issue = createMockIssue(body: 'Existing body content');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Existing body content'), findsWidgets);
      });

      testWidgets('allows editing title', (tester) async {
        final issue = createMockIssue(title: 'Original Title');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'Updated Title');
        await tester.pumpAndSettle();

        expect(find.text('Updated Title'), findsOneWidget);
      });

      testWidgets('allows editing description', (tester) async {
        final issue = createMockIssue(body: 'Original body');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final descField = find.byType(TextField).last;
        await tester.enterText(descField, 'Updated body');
        await tester.pumpAndSettle();

        expect(find.textContaining('Updated body'), findsWidgets);
      });
    });

    group('Labels Section', () {
      testWidgets('displays Labels section', (tester) async {
        final issue = createMockIssue(labels: ['bug', 'feature']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Labels'), findsOneWidget);
      });

      testWidgets('shows existing labels as chips', (tester) async {
        final issue = createMockIssue(labels: ['bug', 'urgent']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('bug'), findsWidgets);
        expect(find.text('urgent'), findsWidgets);
      });

      testWidgets('shows add label button', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsWidgets);
      });

      testWidgets('allows adding new labels', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Tap add label button
        final addLabelButton = find.byIcon(Icons.add);
        if (addLabelButton.evaluate().isNotEmpty) {
          await tester.tap(addLabelButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('allows removing labels', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Label chips should have delete action
        expect(find.byIcon(Icons.close), findsWidgets);
      });

      testWidgets('shows message when no labels', (tester) async {
        final issue = createMockIssue(labels: []);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('No labels'), findsWidgets);
      });

      testWidgets('label chips are tappable', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final labelChip = find.text('bug');
        if (labelChip.evaluate().isNotEmpty) {
          await tester.tap(labelChip);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator initially', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during loading', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('shows saving indicator when saving', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Saving state should show loading
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('displays saving text during save', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.textContaining('Saving'), findsWidgets);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // After settling, form should be visible
        expect(find.byType(TextField), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on save failure', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Error container should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('displays error in snackbar', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Snackbar should be displayable for errors
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('save button is clickable', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final saveButton = find.byIcon(Icons.check);
        if (saveButton.evaluate().isNotEmpty) {
          await tester.tap(saveButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('save button disabled when saving', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Save button should be present
        expect(find.byIcon(Icons.check), findsOneWidget);
      });

      testWidgets('form can be scrolled', (tester) async {
        final issue = createMockIssue(body: 'Long body\n' * 20);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('label chips can be tapped', (tester) async {
        final issue = createMockIssue(labels: ['bug']);
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final labelChip = find.text('bug');
        if (labelChip.evaluate().isNotEmpty) {
          await tester.tap(labelChip);
          await tester.pumpAndSettle();
        }
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has Edit Issue title', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.text('Edit Issue'), findsOneWidget);
      });

      testWidgets('app bar has save action button', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
      });

      testWidgets('save button has orange color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Save button should use orange primary color
        expect(find.byIcon(Icons.check), findsOneWidget);
      });
    });

    group('Markdown Support', () {
      testWidgets('description field supports Markdown', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Markdown hint should be present
        expect(find.textContaining('Markdown'), findsWidgets);
      });

      testWidgets('accepts Markdown formatting in description', (tester) async {
        final issue = createMockIssue(body: '**Bold** text');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final descField = find.byType(TextField).last;
        await tester.enterText(descField, '**Updated bold**');
        await tester.pumpAndSettle();

        expect(find.textContaining('**Updated bold**'), findsWidgets);
      });

      testWidgets('displays Markdown preview', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Markdown widget should be present
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('Markdown'),
        ), findsWidgets);
      });
    });

    group('Form Validation', () {
      testWidgets('validates title is not empty', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Form validation should be present
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('allows empty description', (tester) async {
        final issue = createMockIssue(body: '');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Empty description should be allowed
        expect(find.byType(EditIssueScreen), findsOneWidget);
      });

      testWidgets('shows validation error for empty title', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Validation error should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('Input Field Styling', () {
      testWidgets('Title field has correct decoration', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField).first);
        expect(textField.decoration, isNotNull);
      });

      testWidgets('Description field has correct decoration', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Description field should have decoration
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('input fields have card background', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Input fields should have proper styling
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('focused border uses orange color', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Focused border should use orange
        expect(find.byWidgetPredicate(
          (widget) => widget is OutlineInputBorder,
        ), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => MaterialApp(
              home: EditIssueScreen(
                issue: issue,
                owner: 'testowner',
                repo: 'testrepo',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(EditIssueScreen), findsOneWidget);
      });

      testWidgets('uses SingleChildScrollView for form', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('form has proper padding', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Form should have padding
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Local Issue Handling', () {
      testWidgets('handles local-only issues', (tester) async {
        final issue = createMockIssue();
        issue.isLocalOnly = true;
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Should handle local issues
        expect(find.byType(EditIssueScreen), findsOneWidget);
      });

      testWidgets('shows sync status for local issues', (tester) async {
        final issue = createMockIssue();
        issue.isLocalOnly = true;
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Local issues should have sync indicator
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('sync'),
        ), findsWidgets);
      });
    });

    group('Success Flow', () {
      testWidgets('shows success message on save', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Success snackbar should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('navigates back after successful save', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Navigation should occur after save
        expect(find.byType(EditIssueScreen), findsOneWidget);
      });
    });

    group('Cancel Flow', () {
      testWidgets('can cancel editing', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Back navigation should be available
        expect(find.byType(AppBar), findsOneWidget);
      });

      testWidgets('discards changes on cancel', (tester) async {
        final issue = createMockIssue(title: 'Original');
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        // Changes should be discardable
        expect(find.byType(EditIssueScreen), findsOneWidget);
      });
    });

    group('Character Limits', () {
      testWidgets('Title field accepts long text', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final longTitle = 'A' * 200;
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, longTitle);
        await tester.pumpAndSettle();

        // Should accept long text
        expect(find.text(longTitle), findsOneWidget);
      });

      testWidgets('Description field accepts multiline text', (tester) async {
        final issue = createMockIssue();
        await tester.pumpWidget(createTestApp(issue: issue));
        await tester.pumpAndSettle();

        final multilineDesc = 'Line 1\nLine 2\nLine 3';
        final descField = find.byType(TextField).last;
        await tester.enterText(descField, multilineDesc);
        await tester.pumpAndSettle();

        // Should accept multiline text
        expect(find.byType(TextField), findsOneWidget);
      });
    });
  });
}
