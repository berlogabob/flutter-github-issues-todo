import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/project_item.dart';
import 'package:gitdoit/screens/project_board_screen.dart';

import '../support/test_harness.dart';
import '../support/widget_pump_helpers.dart';

void main() {
  final harness = TestHarness.shared;

  const writableProject = ProjectV2(
    id: 'project-1',
    number: 1,
    title: 'Roadmap',
    ownerLogin: 'octo-org',
    ownerType: ProjectOwnerType.organization,
    url: 'https://github.com/orgs/octo-org/projects/1',
    viewerCanUpdate: true,
  );

  setUpAll(harness.install);
  setUp(harness.reset);
  tearDownAll(harness.dispose);

  ProjectV2Board boardFor(ProjectV2 project, {bool withStatus = true}) {
    return ProjectV2Board(
      project: project,
      statusFieldId: withStatus ? 'status-field' : null,
      columns: withStatus
          ? const [
              ProjectV2Column(
                fieldId: 'status-field',
                optionId: null,
                name: 'No status',
                color: 'GRAY',
              ),
              ProjectV2Column(
                fieldId: 'status-field',
                optionId: 'todo',
                name: 'Todo',
                color: 'BLUE',
              ),
              ProjectV2Column(
                fieldId: 'status-field',
                optionId: 'doing',
                name: 'Doing',
                color: 'YELLOW',
              ),
            ]
          : const [],
      items: const [
        ProjectV2BoardItem(
          projectItemId: 'project-item-1',
          contentId: 'issue-node-1',
          contentType: ProjectContentType.issue,
          title: 'Ship offline kanban',
          number: 42,
          repoFullName: 'octo-org/mobile',
          state: 'open',
          statusOptionId: 'todo',
          statusName: 'Todo',
          labels: ['feature'],
        ),
      ],
      fetchedAt: DateTime.now(),
    );
  }

  Future<void> pumpBoard(
    WidgetTester tester,
    ProjectV2 project, {
    bool withStatus = true,
  }) async {
    await tester.pumpTestApp(
      ProjectBoardScreen(
        project: project,
        initialBoard: boardFor(project, withStatus: withStatus),
      ),
    );
    await tester.pump();
  }

  testWidgets('renders the cached dynamic board before network work', (
    tester,
  ) async {
    await pumpBoard(tester, writableProject);

    expect(find.text('octo-org / Roadmap'), findsOneWidget);
    expect(find.text('No status'), findsOneWidget);
    expect(find.textContaining('Ship offline kanban'), findsOneWidget);
    expect(find.byType(LongPressDraggable<ProjectV2BoardItem>), findsOneWidget);
    final horizontalBoard = find.byWidgetPredicate(
      (widget) =>
          widget is ListView && widget.scrollDirection == Axis.horizontal,
    );
    await tester.drag(horizontalBoard, const Offset(-650, 0));
    await tester.pump();
    expect(find.text('Doing'), findsOneWidget);
    expect(find.text('Last synced just now'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('filters cached cards locally', (tester) async {
    await pumpBoard(tester, writableProject);

    await tester.enterText(find.byType(TextField), 'not present');
    await tester.pump();

    expect(find.textContaining('Ship offline kanban'), findsNothing);
  });

  testWidgets('keeps read-only projects browsable without drag actions', (
    tester,
  ) async {
    const readOnlyProject = ProjectV2(
      id: 'project-read-only',
      number: 2,
      title: 'Public Roadmap',
      ownerLogin: 'octo-org',
      ownerType: ProjectOwnerType.organization,
      url: '',
    );
    await pumpBoard(tester, readOnlyProject);

    expect(find.textContaining('Ship offline kanban'), findsOneWidget);
    expect(find.byType(LongPressDraggable<ProjectV2BoardItem>), findsNothing);
    final addButton = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.add),
    );
    expect(addButton.onPressed, isNull);
  });

  testWidgets('explains projects without a Status field', (tester) async {
    await pumpBoard(tester, writableProject, withStatus: false);

    expect(
      find.textContaining('This project has no Status field'),
      findsOneWidget,
    );
  });
}
