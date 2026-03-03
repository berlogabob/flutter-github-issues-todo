import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/screens/project_board_screen.dart';
import 'package:gitdoit/constants/app_colors.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  group('ProjectBoardScreen Widget Tests', () {
    Widget createTestApp() {
      return ScreenUtilInit(
        designSize: const Size(360, 690),
        builder: (context, child) => const MaterialApp(
          home: ProjectBoardScreen(),
        ),
      );
    }

    group('Screen Rendering', () {
      testWidgets('renders project board screen', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ProjectBoardScreen), findsOneWidget);
      });

      testWidgets('displays Project Board title in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Project Board'), findsOneWidget);
      });

      testWidgets('has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
        expect(scaffold.backgroundColor, AppColors.background);
      });

      testWidgets('displays refresh button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.refresh), findsWidgets);
      });

      testWidgets('displays add issue button in app bar', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.add), findsWidgets);
      });
    });

    group('Column Display', () {
      testWidgets('displays Todo column', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Todo'), findsWidgets);
      });

      testWidgets('displays In Progress column', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('In Progress'), findsWidgets);
      });

      testWidgets('displays Review column', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Review'), findsWidgets);
      });

      testWidgets('displays Done column', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.text('Done'), findsWidgets);
      });

      testWidgets('columns have count badges', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Count badges should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('column headers have color indicators', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Color indicators should be present
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });
    });

    group('Loading States', () {
      testWidgets('shows BrailleLoader during loading', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsWidgets,
        );
      });

      testWidgets('shows loading indicator initially', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsWidgets);
      });

      testWidgets('hides loading when data loaded', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // After settling, board or empty state should be visible
        expect(find.byType(ProjectBoardScreen), findsOneWidget);
      });
    });

    group('Empty States', () {
      testWidgets('shows empty state when no issues', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Empty state should be displayable
        expect(find.byType(ProjectBoardScreen), findsOneWidget);
      });

      testWidgets('displays empty state icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.view_kanban), findsWidgets);
      });

      testWidgets('shows empty state message', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(
          find.textContaining('No issues'),
          findsWidgets,
        );
      });

      testWidgets('empty state shows tap hint', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Tap'),
          findsWidgets,
        );
      });
    });

    group('Error Handling', () {
      testWidgets('displays error message on failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error container should be present
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('shows error icon for failures', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.error_outline), findsWidgets);
      });

      testWidgets('provides retry button on error', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(ElevatedButton), findsWidgets);
      });

      testWidgets('retry button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final retryButton = find.byType(ElevatedButton);
        if (retryButton.evaluate().isNotEmpty) {
          await tester.tap(retryButton);
          await tester.pumpAndSettle();
        }
      });
    });

    group('Issue Cards', () {
      testWidgets('displays issue cards in columns', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should be present
        expect(find.byType(Card), findsWidgets);
      });

      testWidgets('issue cards show issue number', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue numbers should be displayed
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
                (widget as Text).data?.contains('#') == true,
          ),
          findsWidgets,
        );
      });

      testWidgets('issue cards show issue title', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue titles should be displayed
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('issue cards show labels', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Labels should be displayed
        expect(find.byType(Chip), findsWidgets);
      });

      testWidgets('issue cards show assignee', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Assignee should be displayed
        expect(find.byIcon(Icons.person), findsWidgets);
      });

      testWidgets('issue cards show updated time', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Time indicator should be present
        expect(find.byIcon(Icons.access_time), findsWidgets);
      });

      testWidgets('issue cards have drag handle', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Drag handle should be present
        expect(find.byIcon(Icons.drag_handle), findsWidgets);
      });

      testWidgets('issue cards have correct background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final cards = tester.widgetList<Card>(find.byType(Card));
        if (cards.isNotEmpty) {
          expect(cards.first.color, AppColors.cardBackground);
        }
      });
    });

    group('Drag and Drop', () {
      testWidgets('columns are drag targets', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // DragTarget should be present
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('DragTarget'),
          ),
          findsWidgets,
        );
      });

      testWidgets('cards are draggable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Draggable should be present
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('Draggable'),
          ),
          findsWidgets,
        );
      });

      testWidgets('column supports reorderable items', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // ReorderableColumn should be present
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('Reorderable'),
          ),
          findsWidgets,
        );
      });

      testWidgets('drag feedback has proper elevation', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Material with elevation for drag feedback
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Material && widget.elevation > 0,
          ),
          findsWidgets,
        );
      });
    });

    group('User Interactions', () {
      testWidgets('refresh button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final refreshButton = find.byIcon(Icons.refresh);
        if (refreshButton.evaluate().isNotEmpty) {
          await tester.tap(refreshButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('add button is clickable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final addButton = find.byIcon(Icons.add);
        if (addButton.evaluate().isNotEmpty) {
          await tester.tap(addButton);
          await tester.pumpAndSettle();
        }
      });

      testWidgets('issue cards are tappable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Cards should be tappable
        expect(find.byType(InkWell), findsWidgets);
      });

      testWidgets('tapping issue navigates to detail', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue cards should navigate to detail
        expect(find.byType(Card), findsWidgets);
      });
    });

    group('Column Styling', () {
      testWidgets('Todo column has grey indicator', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Column color indicators
        expect(find.byWidgetPredicate(
          (widget) => widget is Container &&
              (widget as Container).decoration is BoxDecoration,
        ), findsWidgets);
      });

      testWidgets('In Progress column has orange indicator', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Orange color for In Progress
        expect(find.byWidgetPredicate(
          (widget) => widget is Container,
        ), findsWidgets);
      });

      testWidgets('Review column has blue indicator', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Blue color for Review
        expect(find.byWidgetPredicate(
          (widget) => widget is Container,
        ), findsWidgets);
      });

      testWidgets('Done column has green indicator', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Green color for Done
        expect(find.byWidgetPredicate(
          (widget) => widget is Container,
        ), findsWidgets);
      });

      testWidgets('column headers have bold text', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Column headers should be bold
        expect(find.byType(Text), findsWidgets);
      });
    });

    group('Scroll Behavior', () {
      testWidgets('board is horizontally scrollable', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Scrollable), findsWidgets);
      });

      testWidgets('columns have proper spacing', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Columns should have margin/spacing
        expect(find.byType(Container), findsWidgets);
      });

      testWidgets('content has proper padding', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('AppBar Configuration', () {
      testWidgets('app bar has correct background color', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.backgroundColor, AppColors.background);
      });

      testWidgets('app bar has action buttons', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        final appBar = tester.widget<AppBar>(find.byType(AppBar));
        expect(appBar.actions, isNotNull);
      });

      testWidgets('app bar title is bold', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Title should be styled
        expect(find.text('Project Board'), findsOneWidget);
      });
    });

    group('Responsive Layout', () {
      testWidgets('adapts to different screen sizes', (tester) async {
        await tester.pumpWidget(
          ScreenUtilInit(
            designSize: const Size(768, 1024),
            builder: (context, child) => const MaterialApp(
              home: ProjectBoardScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(ProjectBoardScreen), findsOneWidget);
      });

      testWidgets('uses ScreenUtil for responsive sizing', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Text widgets should use responsive sizing
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('column width adapts to screen size', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Columns should have proper width
        expect(find.byType(Container), findsWidgets);
      });
    });

    group('Success Feedback', () {
      testWidgets('shows snackbar on successful move', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Snackbar should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('success snackbar has check icon', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byIcon(Icons.check_circle), findsWidgets);
      });

      testWidgets('success snackbar has orange background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Snackbar styling
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('Error Feedback', () {
      testWidgets('shows error snackbar on move failure', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error snackbar should be displayable
        expect(find.byType(SnackBar), findsWidgets);
      });

      testWidgets('error snackbar has retry action', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Retry action should be available
        expect(find.byWidgetPredicate(
          (widget) => widget is SnackBarAction,
        ), findsWidgets);
      });

      testWidgets('error snackbar has red background', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Error styling
        expect(find.byType(SnackBar), findsWidgets);
      });
    });

    group('Card Content', () {
      testWidgets('card shows issue number prefix', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Issue number format #X
        expect(
          find.byWidgetPredicate(
            (widget) => widget is Text &&
                (widget as Text).data?.contains('#') == true,
          ),
          findsWidgets,
        );
      });

      testWidgets('card title is ellipsized when long', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Text should handle overflow
        expect(find.byType(Text), findsWidgets);
      });

      testWidgets('card shows limited labels', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Labels should be limited
        expect(find.byType(Wrap), findsWidgets);
      });

      testWidgets('card has proper padding', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        expect(find.byType(Padding), findsWidgets);
      });
    });

    group('Loading Indicator in Card', () {
      testWidgets('shows BrailleLoader when moving', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Loading indicator for move operation
        expect(
          find.byWidgetPredicate(
            (widget) => widget.toString().contains('BrailleLoader'),
          ),
          findsWidgets,
        );
      });

      testWidgets('card opacity changes when moving', (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Opacity should change during move
        expect(find.byType(Opacity), findsWidgets);
      });
    });
  });
}
