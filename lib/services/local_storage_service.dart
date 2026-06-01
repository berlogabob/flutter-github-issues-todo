import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/app_error_handler.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../models/repo_item.dart';
import '../models/cached_dashboard_data.dart';

/// Local Storage Service - Persists data between app sessions
class LocalStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const String _reposKey = 'local_repos';
  static const String _userKey = 'local_user';
  static const String _filtersKey = 'local_filters';
  static const String _projectsKey = 'local_projects';
  // For persistent offline storage of repositories
  static const String _syncedReposKey = 'synced_repos';
  static const String _syncedReposTimestampKey = 'synced_repos_timestamp';
  // PERFORMANCE OPTIMIZATION (Task 16.3): Auto-sync settings keys
  static const String _autoSyncWifiKey = 'auto_sync_wifi';
  static const String _autoSyncAnyKey = 'auto_sync_any';

  /// Build a local-only issue using the same core fields as synced issues.
  /// Local issues use a negative `number` to avoid collisions with GitHub IDs.
  IssueItem createStructuredLocalIssue({
    required String title,
    String? bodyMarkdown,
    List<String> labels = const [],
    String? assigneeLogin,
    String? repoFullName,
    String? id,
    ItemStatus status = ItemStatus.open,
  }) {
    final now = DateTime.now();
    final effectiveId = id ?? 'local_${now.millisecondsSinceEpoch}';
    final localNumber =
        _deriveLocalNumberFromId(effectiveId) ?? -now.millisecondsSinceEpoch;

    return IssueItem(
      id: effectiveId,
      title: title,
      number: localNumber,
      bodyMarkdown: bodyMarkdown,
      repoFullName: repoFullName,
      labels: labels,
      assigneeLogin: assigneeLogin,
      status: status,
      createdAt: now,
      updatedAt: now,
      localUpdatedAt: now,
      isLocalOnly: true,
    );
  }

  /// Get vault folder path from secure storage
  Future<String?> getVaultFolder() async {
    try {
      final configuredPath = await _storage.read(key: 'vault_folder');
      final writableConfigured = await _ensureWritableDirectory(configuredPath);
      if (writableConfigured != null) {
        return writableConfigured;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final fallbackPath = '${appDir.path}/GitDoItVault';
      final writableFallback = await _ensureWritableDirectory(fallbackPath);
      if (writableFallback != null) {
        await _storage.write(key: 'vault_folder', value: writableFallback);
        debugPrint('Using fallback vault folder: $writableFallback');
      }
      return writableFallback;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      debugPrint('Error resolving vault folder: $e');
      return null;
    }
  }

  Future<String?> _ensureWritableDirectory(String? path) async {
    if (path == null || path.isEmpty) return null;

    try {
      final dir = Directory(path);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Probe access with a short-lived temp file.
      final probeFile = File('${dir.path}/.gitdoit_write_probe');
      await probeFile.writeAsString('ok');
      try {
        await probeFile.delete();
      } on FileSystemException {
        // Benign TOCTOU race: another process may remove the probe file first.
        if (await probeFile.exists()) {
          rethrow;
        }
      }
      return dir.path;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace, showSnackBar: false);
      debugPrint('Vault path is not writable ($path): $e');
      return null;
    }
  }

  /// Save vault folder permission/path
  Future<void> saveVaultFolderPermission(String folderPath) async {
    try {
      await _storage.write(key: 'vault_folder', value: folderPath);
      debugPrint('Saved vault folder permission: $folderPath');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving vault folder permission: $e');
    }
  }

  /// Save a local-only issue to vault markdown storage.
  ///
  /// Contract boundary:
  /// - Vault markdown files are the source of truth only for local-only issues.
  /// - Synced GitHub issues must not be persisted in vault files.
  ///
  /// Returns `true` when written, `false` when skipped or failed.
  Future<bool> saveLocalIssue(IssueItem issue) async {
    try {
      if (!issue.isLocalOnly) {
        debugPrint(
          'LocalStorageService: Skipped vault write for non-local issue ${issue.id}',
        );
        return false;
      }
      final saved = await _saveIssueToVaultFile(issue);
      if (saved) {
        debugPrint('Saved local issue to vault: ${issue.title}');
      }
      return saved;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving local issue: $e');
      return false;
    }
  }

  /// Save issue state for offline usage using the correct storage boundary.
  ///
  /// - Local-only issues -> vault markdown files.
  /// - Synced GitHub issues -> persistent synced issue storage.
  Future<bool> saveIssueForOfflineState(
    IssueItem issue, {
    String? repoFullName,
  }) async {
    if (issue.isLocalOnly) {
      return saveLocalIssue(issue);
    }

    var effectiveRepoFullName = repoFullName;
    if (effectiveRepoFullName == null || effectiveRepoFullName.isEmpty) {
      effectiveRepoFullName = await _findRepoFullNameByIssueId(issue.id);
    }

    if (effectiveRepoFullName == null || effectiveRepoFullName.isEmpty) {
      debugPrint(
        'LocalStorageService: Missing repoFullName for synced issue ${issue.id}, skip offline persistence',
      );
      return false;
    }

    await upsertSyncedIssue(effectiveRepoFullName, issue);
    return true;
  }

  Future<String?> _findRepoFullNameByIssueId(String issueId) async {
    try {
      final reposData = await getRepos();
      for (final repoData in reposData) {
        final repoFullName =
            (repoData['fullName'] ?? repoData['full_name']) as String?;
        if (repoFullName == null || repoFullName.isEmpty) continue;

        final syncedIssues = await getSyncedIssues(repoFullName);
        final found = syncedIssues.any((issue) => issue.id == issueId);
        if (found) {
          return repoFullName;
        }
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error resolving repo for issue $issueId: $e');
    }
    return null;
  }

  /// Save issue as markdown file in vault folder
  Future<bool> _saveIssueToVaultFile(IssueItem issue) async {
    try {
      final vaultPath = await getVaultFolder();
      if (vaultPath == null) {
        debugPrint('No vault folder configured');
        return false;
      }

      final vaultDir = Directory(vaultPath);
      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
        debugPrint('Created vault folder: $vaultPath');
      }

      // Create safe filename from issue title
      final safeTitle = issue.title
          .replaceAll(RegExp(r'[^\w\s-]'), '')
          .replaceAll(RegExp(r'\s+'), '_')
          .toLowerCase();
      final filename = '${issue.id}_$safeTitle.md';
      final filePath = '$vaultPath/$filename';

      // Build markdown content
      final content = _buildMarkdownContent(issue);

      final file = File(filePath);
      await file.writeAsString(content);
      await _deleteStaleVaultFilesForIssue(issue.id, keepPath: filePath);
      debugPrint('Saved markdown file: $filePath');
      return true;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving issue to vault: $e');
      return false;
    }
  }

  Future<void> _deleteStaleVaultFilesForIssue(
    String issueId, {
    required String keepPath,
  }) async {
    final vaultPath = await getVaultFolder();
    if (vaultPath == null) return;

    final vaultDir = Directory(vaultPath);
    if (!await vaultDir.exists()) return;

    await for (final entity in vaultDir.list()) {
      if (entity is! File || !entity.path.endsWith('.md')) continue;
      if (entity.path == keepPath) continue;

      final fileName = entity.path.split('/').last;
      if (fileName == '$issueId.md' || fileName.startsWith('${issueId}_')) {
        await entity.delete();
        debugPrint('Deleted stale vault file: ${entity.path}');
      }
    }
  }

  /// Build markdown content for issue (GitHub-compatible format)
  String _buildMarkdownContent(IssueItem issue) {
    final buffer = StringBuffer();
    final createdAt = issue.createdAt ?? issue.updatedAt ?? DateTime.now();
    final updatedAt = issue.updatedAt ?? createdAt;
    final localUpdatedAt = issue.localUpdatedAt ?? updatedAt;

    // YAML frontmatter for metadata
    buffer.writeln('---');
    buffer.writeln('id: ${issue.id}');
    buffer.writeln('title: ${issue.title}');
    if (issue.number != null) {
      buffer.writeln('number: ${issue.number}');
    }
    if (issue.labels.isNotEmpty) {
      buffer.writeln('labels: ${issue.labels.join(", ")}');
    }
    if (issue.assigneeLogin != null && issue.assigneeLogin!.isNotEmpty) {
      buffer.writeln('assignee: ${issue.assigneeLogin}');
    }
    if (issue.repoFullName != null && issue.repoFullName!.isNotEmpty) {
      buffer.writeln('repo_full_name: ${issue.repoFullName}');
    }
    buffer.writeln(
      'status: ${issue.status == ItemStatus.open ? "open" : "closed"}',
    );
    buffer.writeln('created_at: ${createdAt.toIso8601String()}');
    buffer.writeln('updated_at: ${updatedAt.toIso8601String()}');
    buffer.writeln('local_updated_at: ${localUpdatedAt.toIso8601String()}');
    if (issue.isLocalOnly) {
      buffer.writeln('local_only: true');
    }
    buffer.writeln('---');
    buffer.writeln();

    // Body content
    if (issue.bodyMarkdown != null && issue.bodyMarkdown!.isNotEmpty) {
      buffer.write(issue.bodyMarkdown);
    } else {
      buffer.write('_No description_');
    }

    return buffer.toString();
  }

  /// Get all locally created issues (from vault folder only)
  Future<List<IssueItem>> getLocalIssues() async {
    return await _loadIssuesFromVault();
  }

  /// Load cached local issues without creating a fallback vault folder.
  ///
  /// Dashboard and detail cache hydration should be read-only. Creating or
  /// probing a vault path while rendering cached data can block first paint.
  Future<List<IssueItem>> getCachedLocalIssues() async {
    return await _loadIssuesFromVault(createFallbackVault: false);
  }

  /// Load issues from vault folder markdown files
  Future<List<IssueItem>> _loadIssuesFromVault({
    bool createFallbackVault = true,
  }) async {
    final List<IssueItem> issues = [];

    try {
      final vaultPath = createFallbackVault
          ? await getVaultFolder()
          : await _storage.read(key: 'vault_folder');
      if (vaultPath == null) return issues;

      final vaultDir = Directory(vaultPath);
      if (!await vaultDir.exists()) return issues;

      await for (final entity in vaultDir.list()) {
        if (entity is File && entity.path.endsWith('.md')) {
          try {
            final content = await entity.readAsString();
            final issue = _parseMarkdownToIssue(entity.path, content);
            if (issue != null) {
              issues.add(issue);
            }
          } catch (e, stackTrace) {
            AppErrorHandler.handle(e, stackTrace: stackTrace);
            debugPrint('Error reading vault file ${entity.path}: $e');
          }
        }
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error loading issues from vault: $e');
    }

    return issues;
  }

  /// Parse markdown file content to IssueItem
  IssueItem? _parseMarkdownToIssue(String filePath, String content) {
    try {
      // Extract ID from filename (e.g., "local_123456789_my_task.md")
      final fileName = filePath.split('/').last;
      // Match everything before the last underscore (ID portion)
      final lastUnderscore = fileName.lastIndexOf('_');
      var id = lastUnderscore > 0
          ? fileName.substring(0, lastUnderscore)
          : fileName.replaceAll('.md', '');

      // Parse YAML frontmatter
      String title = 'Untitled';
      String? body;
      List<String> labels = [];
      ItemStatus status = ItemStatus.open;
      int? number;
      String? assigneeLogin;
      String? repoFullName;
      DateTime? createdAt;
      DateTime? updatedAt;
      DateTime? localUpdatedAt;

      final frontmatterMatch = RegExp(
        r'^---\s*\n(.*?)\n---',
        dotAll: true,
      ).firstMatch(content);
      if (frontmatterMatch != null) {
        final frontmatter = frontmatterMatch.group(1) ?? '';

        // Parse title
        final idMatch = RegExp(
          r'^id:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (idMatch != null) {
          id = idMatch.group(1)?.trim() ?? id;
        }

        // Parse title
        final titleMatch = RegExp(
          r'^title:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (titleMatch != null) {
          title = titleMatch.group(1) ?? title;
        }

        // Parse labels
        final labelsMatch = RegExp(
          r'^labels:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (labelsMatch != null) {
          labels =
              labelsMatch.group(1)?.split(',').map((l) => l.trim()).toList() ??
              [];
        }

        // Parse issue number
        final numberMatch = RegExp(
          r'^number:\s*(-?\d+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (numberMatch != null) {
          number = int.tryParse(numberMatch.group(1) ?? '');
        }

        // Parse assignee
        final assigneeMatch = RegExp(
          r'^assignee:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (assigneeMatch != null) {
          final rawAssignee = assigneeMatch.group(1)?.trim();
          if (rawAssignee != null && rawAssignee.isNotEmpty) {
            assigneeLogin = rawAssignee;
          }
        }

        final repoFullNameMatch = RegExp(
          r'^repo_full_name:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (repoFullNameMatch != null) {
          final rawRepo = repoFullNameMatch.group(1)?.trim();
          if (rawRepo != null && rawRepo.isNotEmpty) {
            repoFullName = rawRepo;
          }
        }

        // Parse status
        final statusMatch = RegExp(
          r'^status:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (statusMatch != null) {
          status = statusMatch.group(1) == 'closed'
              ? ItemStatus.closed
              : ItemStatus.open;
        }

        // Parse created date (new and legacy keys)
        final createdAtMatch = RegExp(
          r'^created_at:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (createdAtMatch != null) {
          try {
            createdAt = DateTime.parse(createdAtMatch.group(1) ?? '');
          } catch (_) {}
        }
        if (createdAt == null) {
          final createdMatch = RegExp(
            r'^created:\s*(.+)$',
            multiLine: true,
          ).firstMatch(frontmatter);
          if (createdMatch != null) {
            try {
              createdAt = DateTime.parse(createdMatch.group(1) ?? '');
            } catch (_) {}
          }
        }

        // Parse updated date
        final updatedAtMatch = RegExp(
          r'^updated_at:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (updatedAtMatch != null) {
          try {
            updatedAt = DateTime.parse(updatedAtMatch.group(1) ?? '');
          } catch (_) {}
        }

        // Parse local updated date
        final localUpdatedAtMatch = RegExp(
          r'^local_updated_at:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (localUpdatedAtMatch != null) {
          try {
            localUpdatedAt = DateTime.parse(localUpdatedAtMatch.group(1) ?? '');
          } catch (_) {}
        }
      }

      // Get body (content after frontmatter)
      final bodyMatch = content.replaceFirst(
        RegExp(r'^---.*?---\s*', dotAll: true),
        '',
      );
      if (bodyMatch.trim().isNotEmpty &&
          bodyMatch.trim() != '_No description_') {
        body = bodyMatch.trim();
      }

      number ??= _deriveLocalNumberFromId(id);
      final effectiveCreatedAt = createdAt ?? updatedAt ?? DateTime.now();
      final effectiveUpdatedAt = updatedAt ?? effectiveCreatedAt;
      final effectiveLocalUpdatedAt = localUpdatedAt ?? effectiveUpdatedAt;

      return IssueItem(
        id: id,
        title: title,
        number: number,
        bodyMarkdown: body,
        repoFullName: repoFullName,
        labels: labels,
        assigneeLogin: assigneeLogin,
        status: status,
        createdAt: effectiveCreatedAt,
        updatedAt: effectiveUpdatedAt,
        localUpdatedAt: effectiveLocalUpdatedAt,
        isLocalOnly: true,
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error parsing markdown file: $e');
      return null;
    }
  }

  int? _deriveLocalNumberFromId(String id) {
    final match = RegExp(r'^local_(\d+)').firstMatch(id);
    if (match == null) {
      return null;
    }
    final timestamp = int.tryParse(match.group(1) ?? '');
    if (timestamp == null) {
      return null;
    }
    return -timestamp;
  }

  /// Remove a local issue (after syncing) - delete from vault folder
  Future<void> removeLocalIssue(String issueId) async {
    try {
      final vaultPath = await getVaultFolder();
      if (vaultPath == null) return;

      final vaultDir = Directory(vaultPath);
      if (!await vaultDir.exists()) return;

      await for (final entity in vaultDir.list()) {
        if (entity is! File || !entity.path.endsWith('.md')) continue;
        final fileName = entity.path.split('/').last;
        if (fileName == '$issueId.md' || fileName.startsWith('${issueId}_')) {
          await entity.delete();
          debugPrint('Deleted vault file: ${entity.path}');
        }
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error removing local issue: $e');
    }
  }

  /// Save user data locally
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userKey, value: json.encode(userData));
      debugPrint('Saved user data: ${userData['login']}');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving user data: $e');
    }
  }

  /// Get saved user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) return null;
      return json.decode(userJson);
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  /// Clear all local data (logout)
  Future<void> clearAllData() async {
    try {
      await _storage.delete(key: _reposKey);
      await _storage.delete(key: _userKey);
      debugPrint('Cleared all local data');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error clearing data: $e');
    }
  }

  /// Get count of local issues
  Future<int> getLocalIssuesCount() async {
    final issues = await getLocalIssues();
    return issues.length;
  }

  /// Save dashboard filters
  Future<void> saveFilters({
    String? filterStatus,
    String? selectedProject,
    List<String>? pinnedRepos,
  }) async {
    try {
      final filters = {
        'filterStatus': filterStatus ?? 'open',
        'selectedProject': selectedProject,
        'pinnedRepos': pinnedRepos ?? [],
        'savedAt': DateTime.now().toIso8601String(),
      };
      await _storage.write(key: _filtersKey, value: json.encode(filters));
      debugPrint('Saved filters: $filters');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving filters: $e');
    }
  }

  /// Get saved dashboard filters
  Future<Map<String, dynamic>> getFilters() async {
    try {
      final filtersJson = await _storage.read(key: _filtersKey);
      if (filtersJson == null || filtersJson.isEmpty) {
        return {
          'filterStatus': 'open',
          'selectedProject': null,
          'pinnedRepos': <String>[],
        };
      }

      final filters = json.decode(filtersJson);
      debugPrint('Loaded filters: $filters');
      return filters;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting filters: $e');
      return {'filterStatus': 'open', 'selectedProject': null};
    }
  }

  /// Save projects locally
  Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    try {
      await _storage.write(
        key: _projectsKey,
        value: json.encode(projects.map((p) => p).toList()),
      );
      debugPrint('Saved ${projects.length} projects');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving projects: $e');
    }
  }

  /// Get saved projects
  Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      final projectsJson = await _storage.read(key: _projectsKey);
      if (projectsJson == null || projectsJson.isEmpty) {
        return [];
      }

      final List<dynamic> projects = json.decode(projectsJson);
      return projects.map((p) => p as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting projects: $e');
      return [];
    }
  }

  /// Save synced issues for a repository
  Future<void> saveSyncedIssues(
    String repoFullName,
    List<IssueItem> issues,
  ) async {
    try {
      final key = 'synced_issues_$repoFullName';
      final issuesForRepo = issues
          .map((issue) => issue.copyWith(repoFullName: repoFullName))
          .toList();
      await _storage.write(
        key: key,
        value: json.encode(issuesForRepo.map((i) => i.toJson()).toList()),
      );

      // Save sync timestamp
      await _storage.write(
        key: '${key}_timestamp',
        value: DateTime.now().toIso8601String(),
      );

      debugPrint('Saved ${issues.length} synced issues for $repoFullName');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving synced issues: $e');
    }
  }

  /// Get synced issues for a repository
  Future<List<IssueItem>> getSyncedIssues(String repoFullName) async {
    try {
      final key = 'synced_issues_$repoFullName';
      final issuesJson = await _storage.read(key: key);

      if (issuesJson == null || issuesJson.isEmpty) {
        return [];
      }

      final List<dynamic> issues = json.decode(issuesJson);
      return issues.map((i) => IssueItem.fromJson(i)).toList();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting synced issues: $e');
      return [];
    }
  }

  /// Upsert a synced (non-local) issue in persistent repository storage.
  ///
  /// Contract boundary:
  /// - Synced GitHub issues live under `synced_issues_{repoFullName}`.
  /// - Vault markdown storage is reserved for local-only issues.
  Future<void> upsertSyncedIssue(String repoFullName, IssueItem issue) async {
    try {
      if (issue.isLocalOnly) {
        debugPrint(
          'LocalStorageService: Skipped synced upsert for local-only issue ${issue.id}',
        );
        return;
      }

      final currentIssues = await getSyncedIssues(repoFullName);
      final index = currentIssues.indexWhere((i) => i.id == issue.id);
      if (index == -1) {
        currentIssues.add(issue);
      } else {
        currentIssues[index] = issue;
      }

      await saveSyncedIssues(repoFullName, currentIssues);
      debugPrint(
        'LocalStorageService: Upserted synced issue ${issue.id} for $repoFullName',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error upserting synced issue: $e');
    }
  }

  /// Save repositories persistently for offline access
  Future<void> saveRepos(List<Map<String, dynamic>> repos) async {
    try {
      await _storage.write(key: _syncedReposKey, value: json.encode(repos));
      await _storage.write(
        key: _syncedReposTimestampKey,
        value: DateTime.now().toIso8601String(),
      );
      debugPrint('Saved ${repos.length} repositories persistently');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving repos: $e');
    }
  }

  /// Get saved repositories for offline access
  Future<List<Map<String, dynamic>>> getRepos() async {
    try {
      final reposJson = await _storage.read(key: _syncedReposKey);
      if (reposJson == null || reposJson.isEmpty) {
        return [];
      }

      final List<dynamic> repos = json.decode(reposJson);
      return repos.map((r) => r as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting repos: $e');
      return [];
    }
  }

  /// Get last sync time for repositories
  Future<DateTime?> getReposSyncTime() async {
    try {
      final timestamp = await _storage.read(key: _syncedReposTimestampKey);
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting repos sync time: $e');
      return null;
    }
  }

  /// Get last sync time for a repository
  Future<DateTime?> getSyncTime(String repoFullName) async {
    try {
      final key = 'synced_issues_$repoFullName';
      final timestamp = await _storage.read(key: '${key}_timestamp');

      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting sync time: $e');
      return null;
    }
  }

  /// Remove synced issues after successful sync to GitHub
  Future<void> removeSyncedIssue(String issueId) async {
    try {
      // Local-only issues are vault-backed; remove from vault storage.
      await removeLocalIssue(issueId);
      debugPrint('Removed synced local issue from vault: $issueId');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error removing synced issue: $e');
    }
  }

  /// Save synced projects
  Future<void> saveSyncedProjects(List<Map<String, dynamic>> projects) async {
    try {
      await _storage.write(
        key: 'synced_projects',
        value: json.encode(projects),
      );
      await _storage.write(
        key: 'synced_projects_timestamp',
        value: DateTime.now().toIso8601String(),
      );
      debugPrint('Saved ${projects.length} synced projects');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving synced projects: $e');
    }
  }

  /// Get synced projects
  Future<List<Map<String, dynamic>>> getSyncedProjects() async {
    try {
      final projectsJson = await _storage.read(key: 'synced_projects');
      if (projectsJson == null || projectsJson.isEmpty) {
        return [];
      }

      final List<dynamic> projects = json.decode(projectsJson);
      return projects.map((p) => p as Map<String, dynamic>).toList();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting synced projects: $e');
      return [];
    }
  }

  /// Get last projects sync time
  Future<DateTime?> getProjectsSyncTime() async {
    try {
      final timestamp = await _storage.read(key: 'synced_projects_timestamp');
      if (timestamp == null) return null;
      return DateTime.parse(timestamp);
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting projects sync time: $e');
      return null;
    }
  }

  /// Save default repository for issue creation
  Future<void> saveDefaultRepo(String repoFullName) async {
    try {
      await _storage.write(key: 'default_repo', value: repoFullName);
      debugPrint('Saved default repo: $repoFullName');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving default repo: $e');
    }
  }

  /// Get default repository for issue creation
  Future<String?> getDefaultRepo() async {
    try {
      final repo = await _storage.read(key: 'default_repo');
      return repo;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting default repo: $e');
      return null;
    }
  }

  // ==================== PINNED REPOS ====================
  static const String _pinnedReposKey = 'pinned_repos';

  /// Save pinned repositories
  Future<void> savePinnedRepos(List<String> fullNames) async {
    try {
      await _storage.write(key: _pinnedReposKey, value: json.encode(fullNames));
      debugPrint('✅ Saved ${fullNames.length} pinned repositories');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving pinned repos: $e');
    }
  }

  /// Get pinned repositories
  Future<List<String>> getPinnedRepos() async {
    try {
      final jsonStr = await _storage.read(key: _pinnedReposKey);
      if (jsonStr == null || jsonStr.isEmpty) return [];
      final List<dynamic> decoded = json.decode(jsonStr);
      return decoded.cast<String>();
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting pinned repos: $e');
      return [];
    }
  }

  /// Save default project for issue creation
  Future<void> saveDefaultProject(String projectName) async {
    try {
      await _storage.write(key: 'default_project', value: projectName);
      debugPrint('Saved default project: $projectName');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving default project: $e');
    }
  }

  /// Get default project for issue creation
  Future<String?> getDefaultProject() async {
    try {
      final project = await _storage.read(key: 'default_project');
      return project;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting default project: $e');
      return null;
    }
  }

  /// Save hide username in repo setting
  Future<void> saveHideUsernameSetting(bool hide) async {
    try {
      await _storage.write(key: 'hide_username', value: hide.toString());
      debugPrint('Saved hide username setting: $hide');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving hide username setting: $e');
    }
  }

  /// Get hide username in repo setting
  Future<bool> getHideUsernameSetting() async {
    try {
      final value = await _storage.read(key: 'hide_username');
      // Default to true (hide username, show just repo name)
      if (value == null) return true;
      return value == 'true';
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting hide username setting: $e');
      return true;
    }
  }

  // PERFORMANCE OPTIMIZATION (Task 16.3): Auto-sync settings methods

  /// Save auto-sync on WiFi setting
  Future<void> saveAutoSyncWifi(bool enabled) async {
    try {
      await _storage.write(key: _autoSyncWifiKey, value: enabled.toString());
      debugPrint('Saved auto-sync WiFi setting: $enabled');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving auto-sync WiFi setting: $e');
    }
  }

  /// Get auto-sync on WiFi setting
  Future<bool> getAutoSyncWifi() async {
    try {
      final value = await _storage.read(key: _autoSyncWifiKey);
      // Default to false for offline-first startup behavior.
      if (value == null) return false;
      return value == 'true';
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting auto-sync WiFi setting: $e');
      return false;
    }
  }

  /// Save auto-sync on any network setting
  Future<void> saveAutoSyncAny(bool enabled) async {
    try {
      await _storage.write(key: _autoSyncAnyKey, value: enabled.toString());
      debugPrint('Saved auto-sync any network setting: $enabled');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving auto-sync any network setting: $e');
    }
  }

  /// Get auto-sync on any network setting
  Future<bool> getAutoSyncAny() async {
    try {
      final value = await _storage.read(key: _autoSyncAnyKey);
      // Default to false (don't use mobile data)
      if (value == null) return false;
      return value == 'true';
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting auto-sync any network setting: $e');
      return false;
    }
  }

  /// Save user login for quick access
  Future<void> saveUserLogin(String login) async {
    try {
      await _storage.write(key: 'user_login', value: login);
      debugPrint('Saved user login: $login');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving user login: $e');
    }
  }

  /// Get saved user login
  Future<String?> getUserLogin() async {
    try {
      return await _storage.read(key: 'user_login');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting user login: $e');
      return null;
    }
  }

  /// Save a boolean value
  Future<void> setBool(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving boolean $key: $e');
    }
  }

  /// Get a boolean value
  Future<bool?> getBool(String key) async {
    try {
      final value = await _storage.read(key: key);
      if (value == null) return null;
      return value == 'true';
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting boolean $key: $e');
      return null;
    }
  }

  // ==================== CACHED DASHBOARD DATA ====================
  // OFFLINE-FIRST (Critical Fix): Methods for loading cached data on startup

  /// Check if cached dashboard data exists
  Future<bool> hasCachedData() async {
    try {
      final repos = await getRepos();
      return repos.isNotEmpty;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error checking cached data: $e');
      return false;
    }
  }

  /// Get age of cached data in minutes
  Future<int> getCachedDataAge() async {
    try {
      final timestamp = await getReposSyncTime();
      if (timestamp == null) return -1;
      return DateTime.now().difference(timestamp).inMinutes;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error getting cached data age: $e');
      return -1;
    }
  }

  /// Load all cached dashboard data at once
  Future<CachedDashboardData> getCachedDashboardData() async {
    try {
      final repos = await getRepos();
      final projects = await getSyncedProjects();
      final localIssues = await getCachedLocalIssues();

      // Load issues for each repo
      final reposWithIssues = <RepoItem>[];
      for (final repoData in repos) {
        try {
          final repo = RepoItem.fromJson(repoData);
          final issues = await getSyncedIssues(repo.fullName);
          repo.children = issues;
          reposWithIssues.add(repo);
        } catch (e, stackTrace) {
          AppErrorHandler.handle(e, stackTrace: stackTrace);
          debugPrint('Error loading repo ${repoData['fullName']}: $e');
        }
      }

      final timestamp = await getReposSyncTime();

      debugPrint(
        'Loaded cached dashboard data: ${reposWithIssues.length} repos, '
        '${projects.length} projects, ${localIssues.length} local issues',
      );

      return CachedDashboardData(
        repositories: reposWithIssues,
        projects: projects,
        localIssues: localIssues,
        timestamp: timestamp,
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error loading cached dashboard data: $e');
      // Return empty data on error
      return CachedDashboardData(
        repositories: [],
        projects: [],
        localIssues: [],
        timestamp: null,
      );
    }
  }
}
