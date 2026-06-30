import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/project_item.dart';

void main() {
  test('board JSON preserves project item and content IDs separately', () {
    final board = ProjectV2Board(
      project: const ProjectV2(
        id: 'project',
        number: 7,
        title: 'Roadmap',
        ownerLogin: 'octo-org',
        ownerType: ProjectOwnerType.organization,
        url: '',
        viewerCanUpdate: true,
      ),
      statusFieldId: 'status',
      columns: const [
        ProjectV2Column(
          fieldId: 'status',
          optionId: 'doing',
          name: 'Doing',
          color: 'YELLOW',
        ),
      ],
      items: const [
        ProjectV2BoardItem(
          projectItemId: 'project-item',
          contentId: 'issue-node',
          contentType: ProjectContentType.issue,
          title: 'Work',
          statusOptionId: 'doing',
          statusName: 'Doing',
        ),
      ],
      fetchedAt: DateTime(2026),
    );

    final decoded = ProjectV2Board.fromJson(board.toJson());

    expect(decoded.items.single.projectItemId, 'project-item');
    expect(decoded.items.single.contentId, 'issue-node');
    expect(decoded.columns.single.color, 'YELLOW');
    expect(decoded.project.ownerType, ProjectOwnerType.organization);
  });

  test('moving to No status clears the option', () {
    const item = ProjectV2BoardItem(
      projectItemId: 'item',
      contentType: ProjectContentType.issue,
      title: 'Work',
      statusOptionId: 'todo',
      statusName: 'Todo',
    );

    final moved = item.copyWith(
      clearStatus: true,
      syncState: ProjectItemSyncState.pending,
    );

    expect(moved.statusOptionId, isNull);
    expect(moved.statusName, isNull);
    expect(moved.syncState, ProjectItemSyncState.pending);
  });
}
