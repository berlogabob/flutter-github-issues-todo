import 'dart:convert';
import 'package:http/http.dart' as http;

import 'github_service.dart';
import '../models/github_repository.dart' as repo_models;
import '../utils/logger.dart';

/// GitHub Repositories API - Repository-related operations
///
/// Handles:
/// - Fetching user repositories
/// - Validating repositories
/// - Creating repositories
class GitHubRepositoriesApi {
  final GitHubService _baseService;
  final http.Client _client;

  GitHubRepositoriesApi(this._baseService) : _client = http.Client();

  /// Get user's repositories
  Future<List<repo_models.GitHubRepository>> getUserRepositories({
    String? token,
    String visibility = 'all',
    int perPage = 100,
  }) async {
    final metric = Logger.startMetric('getUserRepositories', 'GitHub');
    Logger.d('Fetching user repositories', context: 'GitHub');

    try {
      final uri = Uri.parse(
        '${GitHubService.baseUrl}/user/repos?visibility=$visibility&per_page=$perPage',
      );

      final headers = await _baseService.headers;
      final response = await _client.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        final repos = jsonList
            .map((json) => repo_models.GitHubRepository.fromJson(json))
            .toList();

        Logger.i('Fetched ${repos.length} repositories', context: 'GitHub');
        metric.complete(success: true);
        return repos;
      } else {
        Logger.e('Failed to fetch repositories', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        metric.complete(success: false, errorCode: response.statusCode);
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error fetching repositories', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error fetching repositories', error: e, stackTrace: stackTrace, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Validate that a repository exists
  Future<bool> validateRepository({
    required String owner,
    required String repo,
  }) async {
    final metric = Logger.startMetric('validateRepository', 'GitHub');
    Logger.d('Validating repository: $owner/$repo', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/repos/$owner/$repo');
      final response = await _client.get(uri, headers: await _baseService.headers);

      Logger.d('Repository validation response: ${response.statusCode}', context: 'GitHub');

      if (response.statusCode == 200) {
        Logger.i('Repository validated: $owner/$repo', context: 'GitHub');
        metric.complete(success: true);
        return true;
      } else if (response.statusCode == 404) {
        Logger.w('Repository not found: $owner/$repo', context: 'GitHub');
        metric.complete(success: false, errorCode: 404);
        return false;
      } else {
        Logger.e('Repository validation failed', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
        });
        metric.complete(success: false, errorCode: response.statusCode);
        return false;
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error validating repository', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      return false;
    } catch (e, stackTrace) {
      Logger.e('Error validating repository', error: e, stackTrace: stackTrace, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      return false;
    }
  }

  /// Create a new repository
  Future<repo_models.GitHubRepository> createRepository({
    required String name,
    String? description,
    bool isPrivate = false,
    bool hasIssues = true,
    bool hasWiki = false,
    bool autoInit = true,
  }) async {
    final metric = Logger.startMetric('createRepository', 'GitHub');
    Logger.d('Creating repository: $name', context: 'GitHub');

    try {
      final uri = Uri.parse('${GitHubService.baseUrl}/user/repos');

      final requestBody = <String, dynamic>{
        'name': name,
        'private': isPrivate,
        'has_issues': hasIssues,
        'has_wiki': hasWiki,
        'auto_init': autoInit,
      };

      if (description != null && description.isNotEmpty) {
        requestBody['description'] = description;
      }

      final response = await _client.post(
        uri,
        headers: await _baseService.headers,
        body: json.encode(requestBody),
      );

      if (response.statusCode == 201) {
        final repo = repo_models.GitHubRepository.fromJson(json.decode(response.body));
        Logger.i('Created repository: ${repo.fullName}', context: 'GitHub');
        metric.complete(success: true);
        return repo;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorBody['message'] as String? ?? 'Unknown error';
        Logger.e('Failed to create repository', context: 'GitHub', metadata: {
          'status_code': response.statusCode,
          'error': errorMessage,
        });
        metric.complete(success: false, errorCode: response.statusCode, errorMessage: errorMessage);
        throw Exception('Failed to create repository: $errorMessage');
      }
    } on http.ClientException catch (e) {
      Logger.e('Network error creating repository', error: e, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      throw Exception('Network error. Please check your internet connection.');
    } catch (e, stackTrace) {
      Logger.e('Error creating repository', error: e, stackTrace: stackTrace, context: 'GitHub');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Dispose HTTP client
  void dispose() {
    _client.close();
    Logger.d('GitHubRepositoriesApi disposed', context: 'GitHub');
  }
}
