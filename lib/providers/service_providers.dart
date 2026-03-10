import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/github_api_service.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';
import '../services/oauth_service.dart';
import '../services/pending_operations_service.dart';
import '../services/cache_service.dart';

/// GitHub API Service Provider
class GitHubApiServiceNotifier extends Notifier<GitHubApiService> {
  @override
  GitHubApiService build() => GitHubApiService();
}

final githubApiServiceProvider =
    NotifierProvider<GitHubApiServiceNotifier, GitHubApiService>(
      GitHubApiServiceNotifier.new,
    );

/// Local Storage Service Provider
class LocalStorageServiceNotifier extends Notifier<LocalStorageService> {
  @override
  LocalStorageService build() => LocalStorageService();
}

final localStorageServiceProvider =
    NotifierProvider<LocalStorageServiceNotifier, LocalStorageService>(
      LocalStorageServiceNotifier.new,
    );

/// Sync Service Provider
class SyncServiceNotifier extends Notifier<SyncService> {
  @override
  SyncService build() => SyncService();
}

final syncServiceProvider = NotifierProvider<SyncServiceNotifier, SyncService>(
  SyncServiceNotifier.new,
);

/// OAuth Service Provider
class OAuthServiceNotifier extends Notifier<OAuthService> {
  @override
  OAuthService build() => OAuthService();
}

final oauthServiceProvider =
    NotifierProvider<OAuthServiceNotifier, OAuthService>(
      OAuthServiceNotifier.new,
    );

/// Pending Operations Service Provider
class PendingOperationsServiceNotifier
    extends Notifier<PendingOperationsService> {
  @override
  PendingOperationsService build() => PendingOperationsService();
}

final pendingOperationsServiceProvider =
    NotifierProvider<
      PendingOperationsServiceNotifier,
      PendingOperationsService
    >(PendingOperationsServiceNotifier.new);

/// Cache Service Provider
class CacheServiceNotifier extends Notifier<CacheService> {
  @override
  CacheService build() => CacheService();
}

final cacheServiceProvider =
    NotifierProvider<CacheServiceNotifier, CacheService>(
      CacheServiceNotifier.new,
    );
