import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';

/// Local Storage Service - Persists data between app sessions
class LocalStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _issuesKey = 'local_issues';
  static const String _reposKey = 'local_repos';
  static const String _userKey = 'local_user';
  static const String _filtersKey = 'local_filters';
  static const String _projectsKey = 'local_projects';

  /// Save a locally created issue
  Future<void> saveLocalIssue(IssueItem issue) async {
    try {
      final issuesJson = await _storage.read(key: _issuesKey);
      List<dynamic> issues = [];

      if (issuesJson != null && issuesJson.isNotEmpty) {
        issues = json.decode(issuesJson);
      }

      issues.add(issue.toJson());
      await _storage.write(key: _issuesKey, value: json.encode(issues));
      debugPrint('Saved local issue: ${issue.title}');
    } catch (e) {
      debugPrint('Error saving local issue: $e');
    }
  }

  /// Get all locally created issues
  Future<List<IssueItem>> getLocalIssues() async {
    try {
      final issuesJson = await _storage.read(key: _issuesKey);
      if (issuesJson == null || issuesJson.isEmpty) {
        return [];
      }

      final List<dynamic> issues = json.decode(issuesJson);
      return issues.map((i) => IssueItem.fromJson(i)).toList();
    } catch (e) {
      debugPrint('Error getting local issues: $e');
      return [];
    }
  }

  /// Remove a local issue (after syncing)
  Future<void> removeLocalIssue(String issueId) async {
    try {
      final issues = await getLocalIssues();
      issues.removeWhere((i) => i.id == issueId);
      await _storage.write(key: _issuesKey, value: json.encode(issues));
    } catch (e) {
      debugPrint('Error removing local issue: $e');
    }
  }

  /// Save user data locally
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    try {
      await _storage.write(key: _userKey, value: json.encode(userData));
      debugPrint('Saved user data: ${userData['login']}');
    } catch (e) {
      debugPrint('Error saving user data: $e');
    }
  }

  /// Get saved user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userJson = await _storage.read(key: _userKey);
      if (userJson == null) return null;
      return json.decode(userJson);
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
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
    } catch (e) {
      debugPrint('Error getting projects sync time: $e');
      return null;
    }
  }

  /// Save default repository for issue creation
  Future<void> saveDefaultRepo(String repoFullName) async {
    try {
      await _storage.write(key: 'default_repo', value: repoFullName);
      debugPrint('Saved default repo: $repoFullName');
    } catch (e) {
      debugPrint('Error saving default repo: $e');
    }
  }

  /// Get default repository for issue creation
  Future<String?> getDefaultRepo() async {
    try {
      final repo = await _storage.read(key: 'default_repo');
      return repo;
    } catch (e) {
      debugPrint('Error getting default repo: $e');
      return null;
    }
  }

  /// Save default project for issue creation
  Future<void> saveDefaultProject(String projectName) async {
    try {
      await _storage.write(key: 'default_project', value: projectName);
      debugPrint('Saved default project: $projectName');
    } catch (e) {
      debugPrint('Error saving default project: $e');
    }
  }

  /// Get default project for issue creation
  Future<String?> getDefaultProject() async {
    try {
      final project = await _storage.read(key: 'default_project');
      return project;
    } catch (e) {
      debugPrint('Error getting default project: $e');
      return null;
    }
  }
}
