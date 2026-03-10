import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/cache_service.dart';
import 'package:gitdoit/services/pending_operations_service.dart';
import 'package:gitdoit/models/pending_operation.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

void main() {
  group('Sprint 15 - Service Tests', () {
    group('CacheService for Sprint 15', () {
      late CacheService cacheService;

      setUpAll(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      setUp(() async {
        cacheService = CacheService();
        await cacheService.init();
      });

      tearDown(() async {
        await cacheService.clear();
      });

      test('Cache assignees with TTL', () async {
        final assignees = [
          {'login': 'user1', 'avatar_url': 'url1'},
          {'login': 'user2', 'avatar_url': 'url2'},
        ];

        // Cache assignees for 5 minutes
        await cacheService.set(
          'assignees_owner_repo',
          assignees,
          ttl: const Duration(minutes: 5),
        );

        final cached = cacheService.get<List>('assignees_owner_repo');
        expect(cached, isNotNull);
        expect(cached!.length, 2);
      });

      test('Cache labels with TTL', () async {
        final labels = [
          {'name': 'bug', 'color': 'FF0000'},
          {'name': 'feature', 'color': '00FF00'},
        ];

        // Cache labels for 5 minutes
        await cacheService.set(
          'labels_owner_repo',
          labels,
          ttl: const Duration(minutes: 5),
        );

        final cached = cacheService.get<List>('labels_owner_repo');
        expect(cached, isNotNull);
        expect(cached!.length, 2);
      });

      test('Cache user login with TTL', () async {
        // Cache user login for 1 hour
        await cacheService.set(
          'user_login',
          'testuser',
          ttl: const Duration(hours: 1),
        );

        final cached = cacheService.get<String>('user_login');
        expect(cached, 'testuser');
      });

      test('Cache projects with TTL', () async {
        final projects = [
          {'title': 'Project 1', 'closed': false},
          {'title': 'Project 2', 'closed': false},
        ];

        await cacheService.set(
          'projects_user',
          projects,
          ttl: const Duration(minutes: 5),
        );

        final cached = cacheService.get<List>('projects_user');
        expect(cached, isNotNull);
        expect(cached!.length, 2);
      });

      test('Cache expires after TTL', () async {
        await cacheService.set(
          'short_ttl',
          'value',
          ttl: const Duration(milliseconds: 100),
        );

        // Should exist immediately
        expect(cacheService.get<String>('short_ttl'), 'value');

        // Wait for expiration
        await Future.delayed(const Duration(milliseconds: 150));

        // Should be expired
        expect(cacheService.get<String>('short_ttl'), isNull);
      });
    });

    group('PendingOperationsService for Sprint 15', () {
      late PendingOperationsService pendingOps;
      late Directory tempDir;

      setUpAll(() async {
        TestWidgetsFlutterBinding.ensureInitialized();
        tempDir = await getTemporaryDirectory();
        Hive.init(tempDir.path);
      });

      setUp(() async {
        pendingOps = PendingOperationsService();
        await pendingOps.init();
        await pendingOps.clear();
      });

      tearDown(() async {
        await pendingOps.clear();
      });

      test('Queue assignee change operation', () async {
        final operation = PendingOperation.updateAssignee(
          id: 'assignee_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          assignee: 'newuser',
        );

        await pendingOps.addOperation(operation);

        final operations = pendingOps.getAllOperations();
        expect(operations.length, 1);
        expect(operations.first.type, OperationType.updateAssignee);
      });

      test('Queue label update operation', () async {
        final operation = PendingOperation.updateLabels(
          id: 'label_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          labels: ['bug'],
        );

        await pendingOps.addOperation(operation);

        final operations = pendingOps.getAllOperations();
        expect(operations.length, 1);
        expect(operations.first.type, OperationType.updateLabels);
      });

      test('Queue update issue operation', () async {
        final operation = PendingOperation.updateIssue(
          id: 'update_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          data: {'title': 'Updated Title'},
        );

        await pendingOps.addOperation(operation);

        final operations = pendingOps.getOperationsByType(
          OperationType.updateIssue,
        );
        expect(operations.length, 1);
      });

      test('Mark operation as syncing', () async {
        final operation = PendingOperation.updateIssue(
          id: 'sync_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          data: {},
        );

        await pendingOps.addOperation(operation);
        await pendingOps.markAsSyncing('sync_op_1');

        final operations = pendingOps.getAllOperations();
        expect(operations.first.isSyncing, isTrue);
        expect(operations.first.status, OperationStatus.syncing);
      });

      test('Mark operation as completed', () async {
        final operation = PendingOperation.updateIssue(
          id: 'complete_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          data: {},
        );

        await pendingOps.addOperation(operation);
        await pendingOps.markAsCompleted('complete_op_1');

        final operations = pendingOps.getAllOperations();
        expect(operations.first.status, OperationStatus.completed);
      });

      test('Mark operation as failed', () async {
        final operation = PendingOperation.updateIssue(
          id: 'fail_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          data: {},
        );

        await pendingOps.addOperation(operation);
        await pendingOps.markAsFailed('fail_op_1', 'Network error');

        final operations = pendingOps.getAllOperations();
        expect(operations.first.status, OperationStatus.failed);
        expect(operations.first.errorMessage, 'Network error');
      });

      test('Remove completed operation', () async {
        final operation = PendingOperation.updateIssue(
          id: 'remove_op_1',
          issueNumber: 123,
          owner: 'testowner',
          repo: 'testrepo',
          data: {},
        );

        await pendingOps.addOperation(operation);
        await pendingOps.removeOperation('remove_op_1');

        final operations = pendingOps.getAllOperations();
        expect(operations.length, 0);
      });

      test('Clear all operations', () async {
        await pendingOps.addOperation(
          PendingOperation.updateIssue(
            id: 'op_1',
            issueNumber: 123,
            owner: 'testowner',
            repo: 'testrepo',
            data: {},
          ),
        );
        await pendingOps.addOperation(
          PendingOperation.updateLabels(
            id: 'op_2',
            issueNumber: 123,
            owner: 'testowner',
            repo: 'testrepo',
            labels: ['bug'],
          ),
        );

        await pendingOps.clear();

        final operations = pendingOps.getAllOperations();
        expect(operations.length, 0);
      });
    });
  });
}
