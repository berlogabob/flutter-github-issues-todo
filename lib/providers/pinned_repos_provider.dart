import 'dart:developer' as developer;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_storage_service.dart';

/// Provider for pinned repositories list
final pinnedReposProvider = NotifierProvider<PinnedReposNotifier, List<String>>(
  () {
    return PinnedReposNotifier();
  },
);

class PinnedReposNotifier extends Notifier<List<String>> {
  PinnedReposNotifier();

  bool _initialized = false;

  @override
  List<String> build() {
    // Auto-load pinned repos from storage (once)
    if (!_initialized) {
      _initialized = true;
      _loadAsync();
    }
    return const [];
  }

  Future<void> _loadAsync() async {
    try {
      final storage = LocalStorageService();
      final pinned = await storage.getPinnedRepos();
      state = pinned;
    } catch (e) {
      developer.log(
        'Error loading pinned repos: $e',
        name: 'PinnedReposNotifier',
      );
    }
  }

  Future<void> load() async {
    final storage = LocalStorageService();
    state = await storage.getPinnedRepos();
  }

  Future<void> pin(String fullName) async {
    if (state.contains(fullName)) return;
    state = [...state, fullName];
    await _save();
  }

  Future<void> unpin(String fullName) async {
    state = state.where((n) => n != fullName).toList();
    await _save();
  }

  Future<void> _save() async {
    final storage = LocalStorageService();
    await storage.savePinnedRepos(state);
  }
}

/// Provider for main/default repository
final mainRepoProvider = NotifierProvider<MainRepoNotifier, String?>(() {
  return MainRepoNotifier();
});

class MainRepoNotifier extends Notifier<String?> {
  MainRepoNotifier();

  bool _initialized = false;

  @override
  String? build() {
    // Auto-load main repo from storage (once)
    if (!_initialized) {
      _initialized = true;
      _loadAsync();
    }
    return null;
  }

  Future<void> _loadAsync() async {
    try {
      final storage = LocalStorageService();
      final mainRepo = await storage.getDefaultRepo();
      state = mainRepo;
    } catch (e) {
      developer.log('Error loading main repo: $e', name: 'MainRepoNotifier');
    }
  }

  Future<void> load() async {
    final storage = LocalStorageService();
    state = await storage.getDefaultRepo();
  }

  Future<void> setMain(String fullName) async {
    state = fullName;
    final storage = LocalStorageService();
    await storage.saveDefaultRepo(fullName);
  }
}
