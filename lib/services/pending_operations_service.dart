import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/pending_operation.dart';
import '../utils/app_error_handler.dart';

/// Service for managing pending operations queue
class PendingOperationsService {
  static final PendingOperationsService _instance =
      PendingOperationsService._internal();
  factory PendingOperationsService() => _instance;
  PendingOperationsService._internal();

  late Box<dynamic> _box;
  bool _isInitialized = false;
  static const String _boxName = 'pending_operations';

  /// Initialize the service
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      _isInitialized = true;
      debugPrint(
        'PendingOperationsService: Initialized with ${_box.length} pending operations',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('PendingOperationsService: Init failed: $e');
    }
  }

  /// Add operation to queue
  Future<void> addOperation(PendingOperation operation) async {
    if (!_isInitialized) {
      await init();
    }

    try {
      await _box.put(operation.id, jsonEncode(operation.toJson()));
      debugPrint(
        'PendingOperationsService: Added operation ${operation.id} (${operation.type})',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('PendingOperationsService: Failed to add operation: $e');
    }
  }

  /// Get all pending operations
  List<PendingOperation> getAllOperations() {
    if (!_isInitialized) return [];

    try {
      return _box.values.map((e) {
        return PendingOperation.fromJson(
          jsonDecode(e as String) as Map<String, dynamic>,
        );
      }).toList();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Get operations by type
  List<PendingOperation> getOperationsByType(OperationType type) {
    return getAllOperations().where((op) => op.type == type).toList();
  }

  /// Remove operation
  Future<void> removeOperation(String operationId) async {
    if (!_isInitialized) return;

    try {
      await _box.delete(operationId);
      debugPrint('PendingOperationsService: Removed operation $operationId');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Mark operation as syncing
  Future<void> markAsSyncing(String operationId) async {
    if (!_isInitialized) return;

    try {
      final operationJson = _box.get(operationId);
      if (operationJson != null) {
        final operation = PendingOperation.fromJson(
          jsonDecode(operationJson as String) as Map<String, dynamic>,
        );
        operation.isSyncing = true;
        operation.retryCount++;
        await _box.put(operationId, jsonEncode(operation.toJson()));
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Clear all operations
  Future<void> clear() async {
    if (!_isInitialized) return;

    try {
      await _box.clear();
      debugPrint('PendingOperationsService: Cleared all operations');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
    }
  }

  /// Get pending operations count
  int getPendingCount() {
    if (!_isInitialized) return 0;
    return _box.length;
  }

  /// Check if has pending operations
  bool hasPendingOperations() {
    return getPendingCount() > 0;
  }
}
