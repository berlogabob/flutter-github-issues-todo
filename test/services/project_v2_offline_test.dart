import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/models/pending_operation.dart';
import 'package:gitdoit/models/project_item.dart';
import 'package:gitdoit/services/pending_operations_service.dart';
import 'package:gitdoit/services/sync_service.dart';

import '../support/test_harness.dart';

void main() {
  final harness = TestHarness.shared;

  setUpAll(harness.install);
  setUp(harness.reset);
  tearDownAll(harness.dispose);

  test(
    'offline move persists the optimistic board and coalesced command',
    () async {
      const project = ProjectV2(
        id: 'project',
        number: 1,
        title: 'Roadmap',
        ownerLogin: 'me',
        ownerType: ProjectOwnerType.user,
        url: '',
        viewerCanUpdate: true,
      );
      const item = ProjectV2BoardItem(
        projectItemId: 'project-item',
        contentId: 'issue-node',
        contentType: ProjectContentType.issue,
        title: 'Work',
        statusOptionId: 'todo',
        statusName: 'Todo',
      );
      final board = ProjectV2Board(
        project: project,
        statusFieldId: 'status',
        columns: const [
          ProjectV2Column(
            fieldId: 'status',
            optionId: 'todo',
            name: 'Todo',
            color: 'BLUE',
          ),
          ProjectV2Column(
            fieldId: 'status',
            optionId: 'done',
            name: 'Done',
            color: 'GREEN',
          ),
          ProjectV2Column(
            fieldId: 'status',
            optionId: 'review',
            name: 'Review',
            color: 'YELLOW',
          ),
        ],
        items: const [item],
        fetchedAt: DateTime.now(),
      );
      final sync = SyncService();

      final moved = await sync.queueProjectItemStatus(
        board: board,
        item: item,
        column: board.columns[1],
      );
      await sync.queueProjectItemStatus(
        board: moved,
        item: moved.items.single,
        column: board.columns.last,
      );

      final cached = await sync.loadProjectBoardFromCache(project.id);
      final pending = PendingOperationsService().getOperationsByType(
        OperationType.setProjectItemStatus,
      );
      expect(cached!.items.single.syncState, ProjectItemSyncState.pending);
      expect(pending, hasLength(1));
      expect(pending.single.data['optionId'], 'review');
      expect(pending.single.data['previousOptionId'], 'todo');
      sync.dispose();
    },
  );
}
