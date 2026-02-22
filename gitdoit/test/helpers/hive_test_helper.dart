import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

import 'package:gitdoit/models/issue.adapter.dart';

/// Hive Test Helper
///
/// Provides utilities for initializing Hive in tests with a temporary directory.
/// 
/// Usage:
/// ```dart
/// void main() {
///   setUpAll(() async {
///     await HiveTestHelper.init();
///   });
///   
///   tearDownAll(() async {
///     await HiveTestHelper.cleanup();
///   });
/// }
/// ```
class HiveTestHelper {
  static Directory? _tempDir;

  /// Initialize Hive with a temporary directory and register adapters
  static Future<Directory> init() async {
    // Set up temporary directory for Hive
    _tempDir = await Directory.systemTemp.createTemp('hive_test_');

    // Initialize Hive with temp directory
    Hive.init(_tempDir!.path);

    // Register adapters
    Hive.registerAdapter(IssueAdapter());
    Hive.registerAdapter(LabelAdapter());
    Hive.registerAdapter(MilestoneAdapter());
    Hive.registerAdapter(UserAdapter());

    return _tempDir!;
  }

  /// Get the temporary directory path
  static String get tempPath {
    if (_tempDir == null) {
      throw StateError('Hive not initialized. Call init() first.');
    }
    return _tempDir!.path;
  }

  /// Open a box with the given name
  static Future<Box<T>> openBox<T>(String name) async {
    return await Hive.openBox<T>(name);
  }

  /// Delete a box from disk
  static Future<void> deleteBox(String name) async {
    await Hive.deleteBoxFromDisk(name);
  }

  /// Close Hive completely
  static Future<void> close() async {
    await Hive.close();
  }

  /// Clean up temporary directory
  static Future<void> cleanup() async {
    if (_tempDir != null) {
      await Hive.close();
      await _tempDir!.delete(recursive: true);
      _tempDir = null;
    }
  }

  /// Reset Hive state (close all boxes and reinitialize)
  static Future<void> reset() async {
    await Hive.close();
    Hive.init(_tempDir!.path);
  }
}
