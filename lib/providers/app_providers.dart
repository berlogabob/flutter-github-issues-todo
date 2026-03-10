import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/secure_storage_service.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import 'repositories_provider.dart';
import 'service_providers.dart';

/// Auth state class
class AuthState {
  final bool isAuthenticated;
  final String authType;
  final String? token;

  AuthState({
    required this.isAuthenticated,
    required this.authType,
    this.token,
  });
}

/// Auth provider using FutureProvider pattern
final authStateProvider = FutureProvider<AuthState>((ref) async {
  try {
    final token = await SecureStorageService.getToken();
    final authType = await SecureStorageService.instance.read(key: 'auth_type');

    if (token != null && token.isNotEmpty) {
      return AuthState(
        isAuthenticated: true,
        authType: authType ?? 'pat',
        token: token,
      );
    }

    if (authType == 'offline') {
      return AuthState(isAuthenticated: true, authType: 'offline', token: null);
    }

    return AuthState(isAuthenticated: false, authType: 'none', token: null);
  } catch (e) {
    return AuthState(isAuthenticated: false, authType: 'error', token: null);
  }
});

/// Repositories provider - fetches from GitHub API
final reposProvider = FutureProvider<List<RepoItem>>((ref) async {
  final api = ref.read(githubApiServiceProvider);
  final repos = await api.fetchMyRepositories(perPage: 30);

  // Update the local state notifier
  final notifier = ref.read(repositoriesProvider.notifier);
  notifier.setRepos(repos);

  return repos;
});

/// Issues provider for a specific repo
final issuesProvider = FutureProvider.family<List<IssueItem>, String>((
  ref,
  repoFullName,
) async {
  final parts = repoFullName.split('/');
  final api = ref.read(githubApiServiceProvider);
  return await api.fetchIssues(parts[0], parts[1]);
});

/// Local issues provider (offline vault)
final localIssuesProvider = FutureProvider<List<IssueItem>>((ref) async {
  final storage = ref.read(localStorageServiceProvider);
  return await storage.getLocalIssues();
});

/// Sync status provider
final syncStatusProvider = Provider<String>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.syncStatus;
});

/// Last sync time provider
final lastSyncProvider = Provider<DateTime?>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.lastSyncTime;
});

/// Is online provider
final isOnlineProvider = Provider<bool>((ref) {
  final sync = ref.read(syncServiceProvider);
  return sync.isNetworkAvailable;
});
