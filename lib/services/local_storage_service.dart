import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../utils/app_error_handler.dart';
import '../models/issue_item.dart';
import '../models/item.dart';

part 'local_storage_service.g.dart';

/// Local Storage Service - Persists data between app sessions
class LocalStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  static const String _issuesKey = 'local_issues';
  static const String _reposKey = 'local_repos';
  static const String _userKey = 'local_user';
  static const String _filtersKey = 'local_filters';
  static const String _projectsKey = 'local_projects';

  /// Get vault folder path from secure storage
  Future<String?> getVaultFolder() async {
    return await _storage.read(key: 'vault_folder');
  }

  /// Save a locally created issue (only to vault folder - for Syncthing/Nextcloud sync)
  Future<void> saveLocalIssue(IssueItem issue) async {
    try {
      await _saveIssueToVaultFile(issue);
      debugPrint('Saved local issue to vault: ${issue.title}');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving local issue: $e');
    }
  }

  /// Save issue as markdown file in vault folder
  Future<void> _saveIssueToVaultFile(IssueItem issue) async {
    try {
      final vaultPath = await getVaultFolder();
      if (vaultPath == null) {
        debugPrint('No vault folder configured');
        return;
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
      debugPrint('Saved markdown file: $filePath');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error saving issue to vault: $e');
    }
  }

  /// Build markdown content for issue (GitHub-compatible format)
  String _buildMarkdownContent(IssueItem issue) {
    final buffer = StringBuffer();

    // YAML frontmatter for metadata
    buffer.writeln('---');
    buffer.writeln('title: ${issue.title}');
    if (issue.labels.isNotEmpty) {
      buffer.writeln('labels: ${issue.labels.join(", ")}');
    }
    buffer.writeln(
      'status: ${issue.status == ItemStatus.open ? "open" : "closed"}',
    );
    buffer.writeln(
      'created: ${issue.updatedAt?.toIso8601String().split('T').first ?? ""}',
    );
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

  /// Load issues from vault folder markdown files
  Future<List<IssueItem>> _loadIssuesFromVault() async {
    final List<IssueItem> issues = [];

    try {
      final vaultPath = await getVaultFolder();
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
      final id = lastUnderscore > 0
          ? fileName.substring(0, lastUnderscore)
          : fileName.replaceAll('.md', '');

      // Parse YAML frontmatter
      String title = 'Untitled';
      String? body;
      List<String> labels = [];
      ItemStatus status = ItemStatus.open;
      DateTime? updatedAt;

      final frontmatterMatch = RegExp(
        r'^---\s*\n(.*?)\n---',
        dotAll: true,
      ).firstMatch(content);
      if (frontmatterMatch != null) {
        final frontmatter = frontmatterMatch.group(1) ?? '';

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

        // Parse created date
        final createdMatch = RegExp(
          r'^created:\s*(.+)$',
          multiLine: true,
        ).firstMatch(frontmatter);
        if (createdMatch != null) {
          try {
            updatedAt = DateTime.parse(createdMatch.group(1) ?? '');
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

      return IssueItem(
        id: id,
        title: title,
        bodyMarkdown: body,
        labels: labels,
        status: status,
        updatedAt: updatedAt ?? DateTime.now(),
        isLocalOnly: true,
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error parsing markdown file: $e');
      return null;
    }
  }

  /// Remove a local issue (after syncing) - delete from vault folder
  Future<void> removeLocalIssue(String issueId) async {
    try {
      final vaultPath = await getVaultFolder();
      if (vaultPath == null) return;

      final vaultDir = Directory(vaultPath);
      if (!await vaultDir.exists()) return;

      await for (final entity in vaultDir.list()) {
        if (entity is File && entity.path.contains(issueId)) {
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
      await _storage.delete(key: _issuesKey);
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
      await _storage.write(
        key: key,
        value: json.encode(issues.map((i) => i.toJson()).toList()),
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
      final allIssues = await getLocalIssues();
      final remainingIssues = allIssues.where((i) => i.id != issueId).toList();

      // Rewrite local issues without the synced one
      await _storage.write(
        key: _issuesKey,
        value: json.encode(remainingIssues.map((i) => i.toJson()).toList()),
      );

      debugPrint('Removed synced issue: $issueId');
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
}

@Riverpod(keepAlive: true)
LocalStorageService localStorageService(Ref ref) {
  return LocalStorageService();
}
