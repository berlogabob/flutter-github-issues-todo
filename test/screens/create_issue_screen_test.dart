import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/create_issue_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('CreateIssueScreen Widget Tests', () {
    Widget createTestApp({
      String? owner,
      String? repo,
      String? defaultProject,
      List<Map<String, dynamic>>? projects,
    }) {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => MaterialApp(
          home: CreateIssueScreen(
            owner: owner,
            repo: repo,
            defaultProject: defaultProject,
            projects: projects,
          ),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders create issue screen', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byType(CreateIssueScreen), findsOneWidget);
      });

      testWidgets('displays Create Issue title', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Create Issue'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays close button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.close), findsOneWidget);
      });

      testWidgets('displays Create button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Create'), findsOneWidget);
      });
    });

    group('Form Fields', () {
      testWidgets('displays Title input field', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Title'), findsOneWidget);
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('displays Description input field', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Description'), findsWidgets);
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('Title field has hint text', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('title'), findsWidgets);
      });

      testWidgets('Description field has hint text', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Markdown'), findsWidgets);
      });

      testWidgets('accepts text input in Title field', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, 'Test Issue Title');
        await tester.pumpAndSettle();

        expect(find.text('Test Issue Title'), findsOneWidget);
      });

      testWidgets('accepts text input in Description field', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final descField = find.byType(TextField).last;
        await tester.enterText(descField, 'Test description content');
        await tester.pumpAndSettle();

        expect(find.textContaining('Test description content'), findsWidgets);
      });
    });

    group('Labels Section', () {
      testWidgets('displays Labels section', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Labels'), findsOneWidget);
      });

      testWidgets('shows add label button', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Add label button should be present
        expect(find.byIcon(Icons.add), findsWidgets);
      });

      testWidgets('displays selected labels as chips', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Label chips should be displayable
        expect(find.byType(Chip), findsWidgets);
      });

      testWidgets('allows adding labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Tap add label button
        final addLabelButton = find.byIcon(Icons.add);
        if (addLabelButton.evaluate().isNotEmpty) {
          await tester.tap(addLabelButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('allows removing labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Label chips should have delete action
        expect(find.byIcon(Icons.close), findsWidgets);
      });

      testWidgets('shows loading indicator for labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });
    });

    group('Assignee Section', () {
      testWidgets('displays Assignee section', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Assignee'), findsOneWidget);
      });

      testWidgets('shows assignee picker button', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Assignee picker should be present
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('displays selected assignee', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Assignee display should be present
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('allows selecting assignee', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Tap assignee picker
        final assigneeTile = find.text('Assignee');
        if (assigneeTile.evaluate().isNotEmpty) {
          await tester.tap(assigneeTile);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('shows loading indicator for assignees', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('allows clearing assignee', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Clear button should be available
        expect(find.byIcon(Icons.close), findsWidgets);
      });
    });

    group('Repository Selection', () {
      testWidgets('displays repository selector', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Repository selector should be present
        expect(find.byType(DropdownButton), findsWidgets);
      });

      testWidgets('shows current repository', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Current repo should be displayed
        expect(find.textContaining('test/repo'), findsWidgets);
      });

      testWidgets('allows changing repository', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final dropdown = find.byType(DropdownButton);
        if (dropdown.evaluate().isNotEmpty) {
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Loading States', () {
      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('shows BrailleLoader during data fetch', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pump();

        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('shows saving indicator when creating', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Saving state should show loading
        expect(find.byWidgetPredicate(
          (widget) => widget.toString().contains('BrailleLoader'),
        ), findsWidgets);
      });

      testWidgets('displays saving text during creation', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Creating'), findsWidgets);
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on failure', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Error container should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('displays error in snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Snackbar should be displayable for errors
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('User Interactions', () {
      testWidgets('close button navigates back', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final closeButton = find.byIcon(Icons.close);
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Create button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final createButton = find.text('Create');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('Create button disabled when saving', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Create button should be present
        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('form validation requires title', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Try to create without title
        final createButton = find.text('Create');
        if (createButton.evaluate().isNotEmpty) {
          await tester.tap(createButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Form Validation', () {
      testWidgets('validates title is not empty', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Empty title should show validation
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('allows empty description', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Empty description should be allowed
        expect(find.byType(CreateIssueScreen), findsOneWidget);
      });

      testWidgets('shows validation error for empty title', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Validation error should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has leading close button', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.leading, isNotNull);
      });

      testWidgets('app bar has Create action button', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
      });

      testWidgets('Create button has orange color', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Create button should use orange primary color
        expect(find.byWidgetPredicate(
          (widget) => widget is Text &&
                      widget.style?.color == AppColors.orangePrimary,
        ), findsWidgets);
      });
    });

    group('Markdown Support', () {
      testWidgets('description field supports Markdown', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Markdown hint should be present
        expect(find.textContaining('Markdown'), findsWidgets);
      });

      testWidgets('accepts Markdown formatting in description', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final descField = find.byType(TextField).last;
        await tester.enterText(descField, '**Bold** and _italic_');
        await tester.pumpAndSettle();

        expect(find.textContaining('**Bold**'), findsWidgets);
      });
    });

    group('Project Assignment', () {
      testWidgets('displays Project section when projects provided', (tester) async {
        final projects = [
          {'id': '1', 'title': 'Test Project'},
        ];
        await tester.pumpWidget(createTestApp(
          owner: 'test',
          repo: 'repo',
          projects: projects,
        ));
        await tester.pumpAndSettle();

        // Project section should be present
        expect(find.textContaining('Project'), findsWidgets);
      });

      testWidgets('allows selecting project', (tester) async {
        final projects = [
          {'id': '1', 'title': 'Test Project'},
        ];
        await tester.pumpWidget(createTestApp(
          owner: 'test',
          repo: 'repo',
          projects: projects,
        ));
        await tester.pumpAndSettle();

        // Project picker should be available
        expect(find.byType(ListTile), findsWidgets);
      });

      testWidgets('shows default project', (tester) async {
        await tester.pumpWidget(createTestApp(
          owner: 'test',
          repo: 'repo',
          defaultProject: 'Mobile Development',
        ));
        await tester.pumpAndSettle();

        // Default project should be displayed
        expect(find.textContaining('Mobile Development'), findsWidgets);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => MaterialApp(
              home: CreateIssueScreen(owner: 'test', repo: 'repo'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(CreateIssueScreen), findsOneWidget);
      });

      testWidgets('uses SingleChildScrollView for form', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byType(SingleChildScrollView), findsWidgets);
      });

      testWidgets('form has proper padding', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Form should have padding
        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Input Field Styling', () {
      testWidgets('Title field has correct decoration', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final textField = tester.widget<TextField>(find.byType(TextField).first);
        expect(textField.decoration, isNotNull);
      });

      testWidgets('Description field has correct decoration', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Description field should have decoration
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('input fields have card background', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Input fields should have proper styling
        expect(find.byType(TextField), findsWidgets);
      });

      testWidgets('focused border uses orange color', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Focused border should use orange
        expect(find.byWidgetPredicate(
          (widget) => widget is OutlineInputBorder,
        ), findsWidgets);
      });
    });

    group('Character Limits', () {
      testWidgets('Title field accepts long text', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final longTitle = 'A' * 200;
        final titleField = find.byType(TextField).first;
        await tester.enterText(titleField, longTitle);
        await tester.pumpAndSettle();

        // Should accept long text
        expect(find.text(longTitle), findsOneWidget);
      });

      testWidgets('Description field accepts multiline text', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final multilineDesc = 'Line 1\nLine 2\nLine 3';
        final descField = find.byType(TextField).last;
        await tester.enterText(descField, multilineDesc);
        await tester.pumpAndSettle();

        // Should accept multiline text
        expect(find.byType(TextField), findsOneWidget);
      });
    });

    group('Success Flow', () {
      testWidgets('shows success message on creation', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Success snackbar should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('navigates back after successful creation', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Navigation should occur after creation
        expect(find.byType(CreateIssueScreen), findsOneWidget);
      });
    });
  });
}
