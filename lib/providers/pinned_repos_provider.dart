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

  @override
  List<String> build() {
    return [];
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

  @override
  String? build() {
    return null;
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
