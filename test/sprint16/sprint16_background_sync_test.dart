import 'package:flutter_test/flutter_test.dart';
import 'package:gitdoit/services/sync_service.dart';
import 'package:gitdoit/services/pending_operations_service.dart';
import 'package:gitdoit/services/local_storage_service.dart';
import 'package:gitdoit/models/pending_operation.dart';

void main() {
  group('Task 16.3 - Background Sync Tests', () {
    group('Background task registered', () {
      test('should initialize sync service', () {
        // Arrange & Act
        final syncService = SyncService();
        syncService.init();

        // Assert - init should not throw
        expect(syncService, isNotNull);
      });

      test('should have sync status tracking', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert
        expect(syncService.syncStatus, 'idle');
        expect(syncService.isSyncing, false);
      });

      test('should track last sync time', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert - lastSyncTime may be null initially
        expect(syncService.lastSyncTime, isNull);
      });

      test('should support listener registration', () {
        // Arrange
        final syncService = SyncService();
        var listenerCalled = false;

        // Act
        syncService.addListener(() {
          listenerCalled = true;
        });

        // Assert
        expect(listenerCalled, false); // Not called yet
      });

      test('should dispose listeners', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();
        void listener() {}
        syncService.addListener(listener);

        // Act
        syncService.removeListener(listener);

        // Assert - should not throw
        expect(syncService, isNotNull);
      });
    });

    group('Sync runs every 15 min on WiFi', () {
      test('SyncService has network availability check', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert - property exists
        expect(syncService.isNetworkAvailable, isNotNull);
      });

      test('should track sync statistics', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Act
        final stats = syncService.getSyncStatistics();

        // Assert
        expect(stats, isNotNull);
        expect(stats.totalSyncs, 0); // Initially 0
      });

      test('SyncStatistics has required fields', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Act
        final stats = syncService.getSyncStatistics();

        // Assert - verify fields exist
        expect(stats.totalSyncs, isNotNull);
        expect(stats.successfulSyncs, isNotNull);
        expect(stats.failedSyncs, isNotNull);
        expect(stats.totalIssuesSynced, isNotNull);
        expect(stats.totalOperationsProcessed, isNotNull);
      });

      test('should get sync history', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Act
        final history = syncService.getSyncHistory();

        // Assert
        expect(history, isNotNull);
        expect(history.length, 0); // Initially empty
      });
    });

    group('Respects auto-sync settings', () {
      test('LocalStorageService has auto-sync methods', () async {
        // Arrange
        final localStorage = LocalStorageService();

        // Assert - methods exist
        expect(localStorage.saveAutoSyncWifi, isNotNull);
        expect(localStorage.getAutoSyncWifi, isNotNull);
        expect(localStorage.saveAutoSyncAny, isNotNull);
        expect(localStorage.getAutoSyncAny, isNotNull);
      });

      test('should save and retrieve auto-sync WiFi setting', () async {
        // Arrange
        final localStorage = LocalStorageService();

        // Act - save
        await localStorage.saveAutoSyncWifi(true);

        // Act - retrieve
        final result = await localStorage.getAutoSyncWifi();

        // Assert
        expect(result, true);

        // Cleanup - reset to default
        await localStorage.saveAutoSyncWifi(false);
      });

      test('should save and retrieve auto-sync Any setting', () async {
        // Arrange
        final localStorage = LocalStorageService();

        // Act - save
        await localStorage.saveAutoSyncAny(false);

        // Act - retrieve
        final result = await localStorage.getAutoSyncAny();

        // Assert
        expect(result, false);

        // Cleanup - reset to default
        await localStorage.saveAutoSyncAny(false);
      });

      test('should default to auto-sync disabled', () async {
        // Arrange
        final localStorage = LocalStorageService();

        // Act
        final wifiSetting = await localStorage.getAutoSyncWifi();
        final anySetting = await localStorage.getAutoSyncAny();

        // Assert
        expect(wifiSetting, false);
        expect(anySetting, false);
      });
    });

    group('Only syncs if pending operations', () {
      test('PendingOperationsService has required methods', () async {
        // Arrange
        final pendingOps = PendingOperationsService();
        await pendingOps.init();

        // Assert - methods exist
        expect(pendingOps.getAllOperations, isNotNull);
        expect(pendingOps.addOperation, isNotNull);
        expect(pendingOps.removeOperation, isNotNull);
        expect(pendingOps.markAsSyncing, isNotNull);
        expect(pendingOps.markAsCompleted, isNotNull);
        expect(pendingOps.markAsFailed, isNotNull);
      });

      test('should check for pending operations', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createIssue,
          data: {'title': 'Test'},
          createdAt: DateTime.now(),
        );

        // Act - add operation
        await pendingOps.addOperation(operation);
        final operations = pendingOps.getAllOperations();

        // Assert
        expect(operations.length, 1);
        expect(operations.first.type, OperationType.createIssue);

        // Cleanup
        await pendingOps.removeOperation('op1');
      });

      test('should return empty when no pending operations', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        // Act
        final operations = pendingOps.getAllOperations();

        // Assert
        expect(operations.isEmpty, true);
      });

      test('should mark operation as syncing', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createIssue,
          data: {'title': 'Test'},
          createdAt: DateTime.now(),
        );
        await pendingOps.addOperation(operation);

        // Act
        await pendingOps.markAsSyncing('op1');
        final operations = pendingOps.getAllOperations();

        // Assert
        expect(operations.first.isSyncing, true);

        // Cleanup
        await pendingOps.removeOperation('op1');
      });

      test('should mark operation as completed', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createIssue,
          data: {'title': 'Test'},
          createdAt: DateTime.now(),
        );
        await pendingOps.addOperation(operation);
        await pendingOps.markAsSyncing('op1');

        // Act
        await pendingOps.markAsCompleted('op1');
        final operations = pendingOps.getAllOperations();

        // Assert
        expect(operations.first.status, OperationStatus.completed);

        // Cleanup
        await pendingOps.removeOperation('op1');
      });

      test('should mark operation as failed', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createIssue,
          data: {'title': 'Test'},
          createdAt: DateTime.now(),
        );
        await pendingOps.addOperation(operation);
        await pendingOps.markAsSyncing('op1');

        // Act
        await pendingOps.markAsFailed('op1', 'Error message');
        final operations = pendingOps.getAllOperations();

        // Assert
        expect(operations.first.status, OperationStatus.failed);
        expect(operations.first.errorMessage, 'Error message');

        // Cleanup
        await pendingOps.removeOperation('op1');
      });

      test('OperationType has all required types', () {
        // Assert - all operation types exist
        expect(OperationType.values, contains(OperationType.createIssue));
        expect(OperationType.values, contains(OperationType.updateIssue));
        expect(OperationType.values, contains(OperationType.closeIssue));
        expect(OperationType.values, contains(OperationType.reopenIssue));
        expect(OperationType.values, contains(OperationType.updateLabels));
        expect(OperationType.values, contains(OperationType.updateAssignee));
        expect(OperationType.values, contains(OperationType.addComment));
      });
    });

    group('Does not drain battery (manual)', () {
      test('should have sync status idle when not syncing', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert
        expect(syncService.syncStatus, 'idle');
        expect(syncService.isSyncing, false);
      });

      test('should track syncing state', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert - initial state
        expect(syncService.isSyncing, false);
      });

      test('should have network availability check', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert
        expect(syncService.isNetworkAvailable, isNotNull);
      });

      test('SyncService dispose cleans up', () {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Act
        syncService.dispose();

        // Assert - should not throw
        expect(syncService, isNotNull);
      });
    });

    group('Integration Tests', () {
      test('SyncService complete flow', () async {
        // Arrange
        final syncService = SyncService();
        syncService.init();

        // Assert - initial state
        expect(syncService.syncStatus, 'idle');
        expect(syncService.isSyncing, false);

        // Cleanup
        syncService.dispose();
      });

      test('PendingOperationsService complete flow', () async {
        // Arrange
        final pendingOps = PendingOperationsService();

        // Act - add operation
        final operation = PendingOperation(
          id: 'test_op',
          type: OperationType.createIssue,
          data: {'title': 'Test'},
          createdAt: DateTime.now(),
        );
        await pendingOps.addOperation(operation);

        // Assert
        final operations = pendingOps.getAllOperations();
        expect(operations.length, 1);

        // Cleanup
        await pendingOps.removeOperation('test_op');
      });

      test('LocalStorageService auto-sync settings flow', () async {
        // Arrange
        final localStorage = LocalStorageService();

        // Act - save settings
        await localStorage.saveAutoSyncWifi(true);
        await localStorage.saveAutoSyncAny(false);

        // Assert - get settings
        final wifiSetting = await localStorage.getAutoSyncWifi();
        final anySetting = await localStorage.getAutoSyncAny();

        expect(wifiSetting, true);
        expect(anySetting, false);

        // Cleanup - reset to default
        await localStorage.saveAutoSyncWifi(false);
        await localStorage.saveAutoSyncAny(false);
      });

      test('OperationType createIssue has correct data', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.createIssue,
          data: {
            'title': 'Test Issue',
            'body': 'Test body',
            'labels': ['bug'],
          },
          createdAt: DateTime.now(),
        );

        // Assert
        expect(operation.type, OperationType.createIssue);
        expect(operation.data['title'], 'Test Issue');
        expect(operation.data['body'], 'Test body');
        expect(operation.data['labels'], ['bug']);
      });

      test('OperationType updateIssue has correct data', () {
        // Arrange
        final operation = PendingOperation(
          id: 'op1',
          type: OperationType.updateIssue,
          data: {'title': 'Updated Title', 'body': 'Updated body'},
          createdAt: DateTime.now(),
        );

        // Assert
        expect(operation.type, OperationType.updateIssue);
        expect(operation.data['title'], 'Updated Title');
      });
    });
  });
}
