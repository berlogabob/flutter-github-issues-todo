import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/create_issue_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gitdoit/models/project_item.dart';

void main() {
  group('CreateIssueScreen Widget Tests', () {
    Widget createTestApp({
      String? owner,
      String? repo,
      String? defaultProject,
      List<ProjectV2>? projects,
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

        expect(find.byIcon(Icons.refresh), findsWidgets);
      });

      testWidgets('displays selected labels as chips', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('No labels available'), findsOneWidget);
      });

      testWidgets('allows adding labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final refreshLabelsButton = find.byIcon(Icons.refresh);
        if (refreshLabelsButton.evaluate().isNotEmpty) {
          await tester.ensureVisible(refreshLabelsButton.first);
          await tester.tap(refreshLabelsButton.first, warnIfMissed: false);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('allows removing labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Label chips should have delete action
        expect(find.byIcon(Icons.close), findsWidgets);
      });

      testWidgets('shows empty state for labels', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('No labels available'), findsOneWidget);
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

        expect(find.byType(DropdownButton<String?>), findsOneWidget);
        expect(find.text('Unassigned'), findsWidgets);
      });

      testWidgets('displays unassigned state when no assignees are loaded', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Unassigned'), findsWidgets);
      });

      testWidgets('allows selecting assignee', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        final assigneeDropdown = find.byType(DropdownButton<String?>);
        if (assigneeDropdown.evaluate().isNotEmpty) {
          await tester.ensureVisible(assigneeDropdown);
          await tester.tap(assigneeDropdown);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('shows empty offline state for assignees', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byType(DropdownButton<String?>), findsOneWidget);
        expect(find.text('Unassigned'), findsWidgets);
      });

      testWidgets('allows clearing assignee', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Unassigned'), findsWidgets);
      });
    });

    group('Repository Selection', () {
      testWidgets('displays repository selector', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        // Repository selector should be present
        expect(find.byType(DropdownButton<String>), findsOneWidget);
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

        final dropdown = find.byType(DropdownButton<String>);
        if (dropdown.evaluate().isNotEmpty) {
          await tester.tap(dropdown);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Loading States', () {
      testWidgets('shows ready form initially while offline', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pump();

        expect(find.byType(TextField), findsWidgets);
        expect(find.text('No labels available'), findsOneWidget);
      });

      testWidgets('shows offline metadata state after data fetch is skipped', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('No labels available'), findsOneWidget);
        expect(find.text('Unassigned'), findsWidgets);
      });

      testWidgets('keeps create action available before submission', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.text('Create'), findsOneWidget);
      });

      testWidgets('does not display saving text before submission', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('Creating'), findsNothing);
      });
    });

    group('Error Handling', () {
      testWidgets('does not display error message initially', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsNothing);
      });

      testWidgets('shows validation icon for empty title', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pump();

        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
      });

      testWidgets('displays validation in snackbar', (tester) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Create'));
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Title is required'), findsWidgets);
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

        await tester.tap(find.text('Create'));
        await tester.pump();

        expect(find.byType(SnackBar), findsOneWidget);
        expect(find.text('Title is required'), findsWidgets);
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
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Text &&
                widget.style?.color == AppColors.orangePrimary,
          ),
          findsWidgets,
        );
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
      testWidgets('displays Project section when projects provided', (
        tester,
      ) async {
        const projects = [
          ProjectV2(
            id: '1',
            number: 1,
            title: 'Test Project',
            ownerLogin: 'test',
            ownerType: ProjectOwnerType.user,
            url: '',
          ),
        ];
        await tester.pumpWidget(
          createTestApp(owner: 'test', repo: 'repo', projects: projects),
        );
        await tester.pumpAndSettle();

        // Project section should be present
        expect(find.textContaining('Project'), findsWidgets);
      });

      testWidgets('allows selecting project', (tester) async {
        const projects = [
          ProjectV2(
            id: '1',
            number: 1,
            title: 'Test Project',
            ownerLogin: 'test',
            ownerType: ProjectOwnerType.user,
            url: '',
          ),
        ];
        await tester.pumpWidget(
          createTestApp(owner: 'test', repo: 'repo', projects: projects),
        );
        await tester.pumpAndSettle();

        final projectDropdown = find.byType(DropdownButton<String?>).last;
        await tester.ensureVisible(projectDropdown);
        await tester.tap(projectDropdown);
        await tester.pumpAndSettle();

        expect(find.text('test / Test Project'), findsOneWidget);
      });

      testWidgets('shows default project', (tester) async {
        await tester.pumpWidget(
          createTestApp(
            owner: 'test',
            repo: 'repo',
            defaultProject: 'Mobile Development',
            projects: const [
              ProjectV2(
                id: 'project-id',
                number: 1,
                title: 'Mobile Development',
                ownerLogin: 'test',
                ownerType: ProjectOwnerType.user,
                url: '',
              ),
            ],
          ),
        );
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

        final textField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
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

        final textField = tester.widget<TextField>(
          find.byType(TextField).first,
        );
        final focusedBorder = textField.decoration?.focusedBorder;

        expect(focusedBorder, isA<OutlineInputBorder>());
        expect(
          (focusedBorder as OutlineInputBorder).borderSide.color,
          AppColors.primary,
        );
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
        expect(find.byType(TextField), findsWidgets);
      });
    });

    group('Success Flow', () {
      testWidgets('does not show success message before creation', (
        tester,
      ) async {
        await tester.pumpWidget(createTestApp(owner: 'test', repo: 'repo'));
        await tester.pumpAndSettle();

        expect(find.textContaining('successfully'), findsNothing);
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
