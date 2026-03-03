import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'secure_storage_service.dart';
import 'cache_service.dart';
import '../utils/app_error_handler.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';

part 'github_api_service.g.dart';

/// GitHub REST API Service
class GitHubApiService {
  String? _token;
  final CacheService _cache = CacheService();

  GitHubApiService({GitHubApiService? githubApi}) {
    // Allow passing instance for inheritance
    if (githubApi != null) {
      _token = githubApi._token;
    }
  }

  /// Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  /// Get stored token using singleton
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _token = null; // Clear cache
    }
    _token ??= await SecureStorageService.getToken();
    debugPrint(
      'GitHubApiService: Token ${_token != null ? "exists (${_token!.length} chars)" : "not found"}',
    );
    return _token;
  }

  /// Clear cached token (call on logout)
  void clearCachedToken() {
    _token = null;
    debugPrint('GitHubApiService: Token cache cleared');
  }

  /// Execute HTTP request with retry logic (exponential backoff)
  /// Retries on network errors and 5xx server errors
  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request, {
    String operation = 'request',
  }) async {
    int retryCount = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        final response = await request();

        // Check for server errors (5xx) - retry these
        if (response.statusCode >= 500 && response.statusCode < 600) {
          if (retryCount < _maxRetries) {
            retryCount++;
            debugPrint(
              'GitHubApiService: $operation failed with ${response.statusCode}, retrying ($retryCount/$_maxRetries)...',
            );
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          }
        }

        return response;
      } on TimeoutException catch (e) {
        if (retryCount < _maxRetries) {
          retryCount++;
          debugPrint(
            'GitHubApiService: $operation timeout, retrying ($retryCount/$_maxRetries): $e',
          );
          await Future.delayed(delay);
          delay *= 2;
        } else {
          debugPrint(
            'GitHubApiService: $operation failed after $retryCount retries',
          );
          rethrow;
        }
      } on SocketException catch (e) {
        if (retryCount < _maxRetries) {
          retryCount++;
          debugPrint(
            'GitHubApiService: Network error, retrying ($retryCount/$_maxRetries): $e',
          );
          await Future.delayed(delay);
          delay *= 2;
        } else {
          debugPrint(
            'GitHubApiService: Network error after $retryCount retries',
          );
          rethrow;
        }
      }
    }
  }

  /// Get authentication headers
  Future<Map<String, String>> get _headers async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      debugPrint('ERROR: No token available');
      throw Exception('No authentication token. Please login again.');
    }

    final headers = {
      'Authorization': 'token $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitDoIt-App',
    };

    debugPrint(
      'Headers created - Authorization: token ${token.substring(0, 6)}...${token.substring(token.length - 4)}',
    );
    return headers;
  }

  /// Test if token is valid (no network required for this test)
  Future<bool> testTokenSaved() async {
    final token = await getToken();
    debugPrint(
      'testTokenSaved - token: ${token != null ? "exists (${token.length} chars)" : "NOT FOUND"}',
    );
    return token != null && token.isNotEmpty;
  }

  /// Fetch current user's repositories with pagination support
  /// 
  /// PERFORMANCE OPTIMIZATION (Task 16.1):
  /// - Paginates results to reduce initial load time
  /// - Caches each page separately for faster subsequent loads
  /// - Default: page=1, per_page=30
  /// - Cache key format: 'repos_page_{page}'
  Future<List<RepoItem>> fetchMyRepositories({
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      debugPrint(
        'fetchMyRepositories() called - page: $page, perPage: $perPage',
      );

      // PERFORMANCE: Cache each page separately for faster subsequent loads
      // Cache key format: 'repos_page_{page}' as per task requirements
      final cacheKey = 'repos_page_$page';
      final cachedRepos = _cache.get<List>(cacheKey);
      if (cachedRepos != null) {
        debugPrint('Cache hit for repositories (page $page)');
        return cachedRepos
            .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final headers = await _headers;
      debugPrint('Making API call to GitHub...');

      final uri = Uri.parse(
        'https://api.github.com/user/repos?sort=updated&per_page=$perPage&page=$page',
      );
      debugPrint('Request URL: $uri');

      // Execute with retry logic
      final response = await _executeWithRetry(
        () => http
            .get(uri, headers: headers)
            .timeout(const Duration(seconds: 15)),
        operation: 'fetchMyRepositories',
      );

      debugPrint('GitHub API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Parsed ${data.length} repositories');
        final repos = data.map((json) => _parseRepo(json)).toList();

        // PERFORMANCE: Cache the result for 5 minutes
        await _cache.set(
          cacheKey,
          repos.map((r) => r.toJson()).toList(),
          ttl: const Duration(minutes: 5),
        );

        return repos;
      } else if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - Token invalid or expired');
        throw Exception(
          'Invalid GitHub token. Please check your token and try again.',
        );
      } else if (response.statusCode == 403) {
        debugPrint('403 Forbidden - API rate limit or permissions issue');
        throw Exception(
          'Access forbidden. Check token permissions (needs repo scope).',
        );
      } else {
        debugPrint('Unexpected status code: ${response.statusCode}');
        throw Exception('Failed to fetch repositories: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      debugPrint('HTTP ClientException: $e');
      throw Exception(
        'Network error: Cannot reach GitHub. Check your internet connection.\n\nDetails: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('Request timeout: $e');
      throw Exception('Request timeout. Check your internet connection.');
    } on SocketException catch (e) {
      debugPrint('SocketException: $e');
      throw Exception(
        'No internet connection. Please check your network settings.\n\nDetails: ${e.message}',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network') ||
          e.toString().contains('failed host lookup')) {
        throw Exception(
          'Cannot connect to GitHub. Check your internet connection.\n\nError: ${e.toString()}',
        );
      }
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Check if more repositories are available for pagination
  /// 
  /// PERFORMANCE OPTIMIZATION (Task 16.1):
  /// - Fetches one extra item to determine if more pages exist
  /// - Returns true if the response has perPage items (meaning more may exist)
  Future<bool> hasMoreRepositories({
    int page = 1,
    int perPage = 30,
  }) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse(
        'https://api.github.com/user/repos?sort=updated&per_page=$perPage&page=$page',
      );

      final response = await _executeWithRetry(
        () => http.get(uri, headers: headers).timeout(const Duration(seconds: 10)),
        operation: 'hasMoreRepositories',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // If we got perPage items, there might be more on the next page
        return data.length >= perPage;
      }
      return false;
    } catch (e) {
      debugPrint('Error checking for more repos: $e');
      return false;
    }
  }

  /// Fetch issues from a repository
  Future<List<IssueItem>> fetchIssues(
    String owner,
    String repo, {
    String state = 'open',
  }) async {
    try {
      // Check cache first
      final cacheKey = 'issues_${owner}_${repo}_$state';
      final cachedIssues = _cache.get<List>(cacheKey);
      if (cachedIssues != null) {
        debugPrint('Cache hit for issues: $owner/$repo');
        return cachedIssues
            .map((json) => IssueItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final headers = await _headers;

      final response = await _executeWithRetry(
        () => http
            .get(
              Uri.parse(
                'https://api.github.com/repos/$owner/$repo/issues?state=$state&per_page=50',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 10)),
        operation: 'fetchIssues',
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final issues = data.map((json) => _parseIssue(json)).toList();

        // Cache the result for 5 minutes
        await _cache.set(
          cacheKey,
          issues.map((i) => i.toJson()).toList(),
          ttl: const Duration(minutes: 5),
        );

        return issues;
      } else {
        throw Exception('Failed to fetch issues');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        throw Exception('No internet connection. Working offline.');
      }
      rethrow;
    }
  }

  /// Fetch a single issue by number
  Future<IssueItem> fetchIssue(
    String owner,
    String repo,
    int issueNumber,
  ) async {
    try {
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/$issueNumber',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return _parseIssue(json.decode(response.body));
      } else {
        throw Exception('Failed to fetch issue: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        throw Exception('No internet connection. Working offline.');
      }
      rethrow;
    }
  }

  /// Create a new issue
  Future<IssueItem> createIssue(
    String owner,
    String repo, {
    required String title,
    String? body,
    List<String>? labels,
    String? assignee,
  }) async {
    try {
      final headers = await _headers;

      // Build request body with only non-null fields
      final Map<String, dynamic> requestBody = {'title': title};

      if (body != null) {
        requestBody['body'] = body;
      }

      if (labels != null && labels.isNotEmpty) {
        // GitHub API expects labels as array of names
        requestBody['labels'] = labels;
      }

      if (assignee != null && assignee.isNotEmpty) {
        requestBody['assignee'] = assignee;
      }

      debugPrint('Creating issue in $owner/$repo with body: $requestBody');

      final response = await _executeWithRetry(
        () => http
            .post(
              Uri.parse('https://api.github.com/repos/$owner/$repo/issues'),
              headers: headers,
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 10)),
        operation: 'createIssue',
      );

      debugPrint('Create issue response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        return _parseIssue(json.decode(response.body));
      } else if (response.statusCode == 422) {
        final errorBody = json.decode(response.body);
        final errors = errorBody['errors'] as List?;
        final errorMsg =
            errors?.map((e) => e['message'] as String).join(', ') ??
            'Unknown error';
        throw Exception('Failed to create issue (422): $errorMsg');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to create issue: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        throw Exception('No internet connection. Issue saved locally.');
      }
      rethrow;
    }
  }

  /// Updates an issue's properties (close/reopen/edit/assignee/labels).
  ///
  /// Supports updating multiple fields in a single request. Only provided
  /// (non-null) fields will be updated.
  ///
  /// Uses GitHub REST API: `PATCH /repos/{owner}/{repo}/issues/{issue_number}`
  ///
  /// Example:
  /// ```dart
  /// // Update assignee
  /// final updated = await githubApi.updateIssue(
  ///   'flutter',
  ///   'flutter',
  ///   123,
  ///   assignees: ['user1', 'user2'],
  /// );
  ///
  /// // Close issue
  /// final closed = await githubApi.updateIssue(
  ///   'flutter',
  ///   'flutter',
  ///   123,
  ///   state: 'closed',
  /// );
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Network errors are caught and return user-friendly messages.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [number] The issue number.
  /// [title] New title (optional).
  /// [body] New description (optional).
  /// [state] New state: 'open' or 'closed' (optional).
  /// [labels] New labels list (replaces existing) (optional).
  /// [assignees] New assignees list (replaces existing) (optional).
  /// Returns the updated [IssueItem].
  Future<IssueItem> updateIssue(
    String owner,
    String repo,
    int number, {
    String? title,
    String? body,
    String? state, // 'open' or 'closed'
    List<String>? labels,
    List<String>? assignees,
  }) async {
    try {
      debugPrint('Updating issue #$number in $owner/$repo...');
      final headers = await _headers;

      // Build request body with only provided fields
      final Map<String, dynamic> requestBody = {};
      if (title != null) requestBody['title'] = title;
      if (body != null) requestBody['body'] = body;
      if (state != null) requestBody['state'] = state;
      if (labels != null) requestBody['labels'] = labels;
      if (assignees != null) requestBody['assignees'] = assignees;

      debugPrint('Update request body: $requestBody');

      final response = await _executeWithRetry(
        () => http
            .patch(
              Uri.parse(
                'https://api.github.com/repos/$owner/$repo/issues/$number',
              ),
              headers: headers,
              body: json.encode(requestBody),
            )
            .timeout(const Duration(seconds: 15)),
        operation: 'updateIssue',
      );

      debugPrint('Update issue response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final updatedIssue = _parseIssue(json.decode(response.body));
        debugPrint('✓ Issue #$number updated successfully');
        return updatedIssue;
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to update issue: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network')) {
        throw Exception('No internet connection. Changes saved locally.');
      }
      rethrow;
    }
  }

  /// Fetch issue comments with pagination support.
  ///
  /// Uses GitHub REST API: `GET /repos/{owner}/{repo}/issues/{issue_number}/comments`
  ///
  /// Example:
  /// ```dart
  /// final comments = await githubApi.fetchIssueComments(
  ///   'flutter',
  ///   'flutter',
  ///   123,
  ///   page: 1,
  ///   perPage: 20,
  /// );
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [issueNumber] The issue number.
  /// [page] Page number for pagination (default: 1).
  /// [perPage] Number of comments per page (default: 20, max: 100).
  /// Returns a list of comment maps.
  Future<List<Map<String, dynamic>>> fetchIssueComments(
    String owner,
    String repo,
    int issueNumber, {
    int page = 1,
    int perPage = 20,
  }) async {
    try {
      debugPrint(
        'Fetching comments for issue #$issueNumber in $owner/$repo (page $page)...',
      );
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/comments?page=$page&per_page=$perPage',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Fetch comments response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> commentsData = json.decode(response.body);
        debugPrint('✓ Fetched ${commentsData.length} comments');
        return commentsData.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to fetch comments: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Add comment to issue
  ///
  /// Uses GitHub REST API: `POST /repos/{owner}/{repo}/issues/{issue_number}/comments`
  ///
  /// Example:
  /// ```dart
  /// await githubApi.addIssueComment('flutter', 'flutter', 123, 'Great issue!');
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [issueNumber] The issue number.
  /// [body] The comment body text (Markdown supported).
  Future<void> addIssueComment(
    String owner,
    String repo,
    int issueNumber,
    String body,
  ) async {
    try {
      debugPrint('Adding comment to issue #$issueNumber in $owner/$repo...');
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/comments',
            ),
            headers: headers,
            body: json.encode({'body': body}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Add comment response status: ${response.statusCode}');

      if (response.statusCode == 201) {
        debugPrint('✓ Comment added successfully');
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to add comment: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Deletes an issue comment.
  ///
  /// Uses GitHub REST API: `DELETE /repos/{owner}/{repo}/issues/comments/{comment_id}`
  ///
  /// Example:
  /// ```dart
  /// await githubApi.deleteIssueComment('flutter', 'flutter', 456);
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [commentId] The comment ID to delete.
  Future<void> deleteIssueComment(
    String owner,
    String repo,
    int commentId,
  ) async {
    try {
      debugPrint('Deleting comment #$commentId in $owner/$repo...');
      final headers = await _headers;

      final response = await http
          .delete(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/comments/$commentId',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Delete comment response status: ${response.statusCode}');

      if (response.statusCode != 204) {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to delete comment: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
      debugPrint('✓ Comment deleted successfully');
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Removes a label from an issue.
  ///
  /// After removing the label, fetches the updated issue to return the
  /// current state with updated labels list.
  ///
  /// Uses GitHub REST API:
  /// - `DELETE /repos/{owner}/{repo}/issues/{issue_number}/labels/{name}`
  /// - `GET /repos/{owner}/{repo}/issues/{issue_number}` (to fetch updated issue)
  ///
  /// Example:
  /// ```dart
  /// final updatedIssue = await githubApi.removeIssueLabel(
  ///   'flutter',
  ///   'flutter',
  ///   123,
  ///   'bug',
  /// );
  /// print('Remaining labels: ${updatedIssue.labels}');
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [issueNumber] The issue number.
  /// [label] The label name to remove.
  /// Returns the updated [IssueItem] with the label removed.
  Future<IssueItem> removeIssueLabel(
    String owner,
    String repo,
    int issueNumber,
    String label,
  ) async {
    try {
      debugPrint(
        'Removing label "$label" from issue #$issueNumber in $owner/$repo...',
      );
      final headers = await _headers;

      // Encode label for URL
      final encodedLabel = Uri.encodeComponent(label);

      final response = await http
          .delete(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/labels/$encodedLabel',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Remove label response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Fetch updated issue to get the new labels
        final issueResponse = await http
            .get(
              Uri.parse(
                'https://api.github.com/repos/$owner/$repo/issues/$issueNumber',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (issueResponse.statusCode == 200) {
          final updatedIssue = _parseIssue(json.decode(issueResponse.body));
          debugPrint('✓ Label "$label" removed successfully');
          return updatedIssue;
        } else {
          throw Exception('Failed to fetch updated issue');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to remove label: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Adds a label to an issue.
  ///
  /// After adding the label, fetches the updated issue to return the
  /// current state with updated labels list.
  ///
  /// Uses GitHub REST API:
  /// - `POST /repos/{owner}/{repo}/issues/{issue_number}/labels`
  /// - `GET /repos/{owner}/{repo}/issues/{issue_number}` (to fetch updated issue)
  ///
  /// Example:
  /// ```dart
  /// final updatedIssue = await githubApi.addIssueLabel(
  ///   'flutter',
  ///   'flutter',
  ///   123,
  ///   'enhancement',
  /// );
  /// print('All labels: ${updatedIssue.labels}');
  /// ```
  ///
  /// Throws [Exception] if the request fails.
  /// Errors are handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// [issueNumber] The issue number.
  /// [label] The label name to add.
  /// Returns the updated [IssueItem] with the label added.
  Future<IssueItem> addIssueLabel(
    String owner,
    String repo,
    int issueNumber,
    String label,
  ) async {
    try {
      debugPrint(
        'Adding label "$label" to issue #$issueNumber in $owner/$repo...',
      );
      final headers = await _headers;

      final response = await http
          .post(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/issues/$issueNumber/labels',
            ),
            headers: headers,
            body: json.encode([label]),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Add label response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // Fetch updated issue to get the new labels
        final issueResponse = await http
            .get(
              Uri.parse(
                'https://api.github.com/repos/$owner/$repo/issues/$issueNumber',
              ),
              headers: headers,
            )
            .timeout(const Duration(seconds: 15));

        if (issueResponse.statusCode == 200) {
          final updatedIssue = _parseIssue(json.decode(issueResponse.body));
          debugPrint('✓ Label "$label" added successfully');
          return updatedIssue;
        } else {
          throw Exception('Failed to fetch updated issue');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to add label: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches available labels for a repository.
  ///
  /// Returns a list of label objects containing:
  /// - `id`: Label ID
  /// - `name`: Label name
  /// - `color`: Hex color code (6 characters, e.g., "0075ca")
  /// - `description`: Label description (optional)
  /// - `url`: API URL for the label
  ///
  /// Uses GitHub REST API: `GET /repos/{owner}/{repo}/labels`
  ///
  /// Example:
  /// ```dart
  /// final labels = await githubApi.fetchRepoLabels('flutter', 'flutter');
  /// for (final label in labels) {
  ///   print('${label['name']}: #${label['color']}');
  /// }
  /// ```
  ///
  /// Throws [Exception] if the request fails or returns a non-200 status code.
  /// Network errors are caught and handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// Returns a list of label maps.
  Future<List<Map<String, dynamic>>> fetchRepoLabels(
    String owner,
    String repo,
  ) async {
    try {
      debugPrint('Fetching labels for $owner/$repo...');
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse('https://api.github.com/repos/$owner/$repo/labels'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Fetch labels response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> labelsData = json.decode(response.body);
        debugPrint('✓ Fetched ${labelsData.length} labels');
        return labelsData.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to fetch labels: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches collaborators (assignees) for a repository.
  ///
  /// Returns a list of collaborator objects containing:
  /// - `login`: User login name
  /// - `id`: User ID
  /// - `avatar_url`: Avatar image URL
  /// - `html_url`: GitHub profile URL
  /// - `type`: User type (e.g., "User")
  ///
  /// Uses GitHub REST API: `GET /repos/{owner}/{repo}/collaborators`
  ///
  /// Example:
  /// ```dart
  /// final collaborators = await githubApi.fetchRepoCollaborators('flutter', 'flutter');
  /// for (final collaborator in collaborators) {
  ///   print('${collaborator['login']}: ${collaborator['avatar_url']}');
  /// }
  /// ```
  ///
  /// Throws [Exception] if the request fails or returns a non-200 status code.
  /// Network errors are caught and handled by [AppErrorHandler].
  ///
  /// [owner] The repository owner's login.
  /// [repo] The repository name.
  /// Returns a list of collaborator maps.
  Future<List<Map<String, dynamic>>> fetchRepoCollaborators(
    String owner,
    String repo,
  ) async {
    try {
      debugPrint('Fetching collaborators for $owner/$repo...');
      final headers = await _headers;

      final response = await http
          .get(
            Uri.parse(
              'https://api.github.com/repos/$owner/$repo/collaborators',
            ),
            headers: headers,
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Fetch collaborators response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> collaboratorsData = json.decode(response.body);
        debugPrint('✓ Fetched ${collaboratorsData.length} collaborators');
        return collaboratorsData.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to fetch collaborators: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      rethrow;
    }
  }

  /// Fetches current authenticated user's information.
  ///
  /// Returns a map containing user data:
  /// - `login`: GitHub username
  /// - `id`: User ID
  /// - `name`: Display name (optional)
  /// - `avatar_url`: Avatar image URL
  /// - `email`: Email address (if public)
  /// - `html_url`: GitHub profile URL
  /// - `company`: Company name (optional)
  /// - `location`: Location (optional)
  ///
  /// Uses GitHub REST API: `GET /user`
  ///
  /// Example:
  /// ```dart
  /// final user = await githubApi.getCurrentUser();
  /// if (user != null) {
  ///   print('Logged in as: ${user['login']}');
  /// }
  /// ```
  ///
  /// Returns `null` if the request fails or user data cannot be retrieved.
  /// Authentication errors (401) are logged but not thrown.
  /// All errors are handled by [AppErrorHandler].
  ///
  /// Returns a map of user data, or `null` on failure.
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final headers = await _headers;
      debugPrint('Fetching user info with headers: ${headers.keys}');

      final response = await http
          .get(Uri.parse('https://api.github.com/user'), headers: headers)
          .timeout(const Duration(seconds: 10));

      debugPrint('User API response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body.substring(0, 200)}...');

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        debugPrint(
          'User login: ${userData['login']}, name: ${userData['name']}',
        );
        return userData;
      } else if (response.statusCode == 401) {
        debugPrint('401 Unauthorized - token may be invalid');
        throw Exception('Invalid token');
      }
      return null;
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Fetches current user's Projects V2 using GraphQL.
  ///
  /// Returns a list of project objects containing:
  /// - `id`: Project node ID (for GraphQL operations)
  /// - `title`: Project title
  /// - `shortDescription`: Project description
  /// - `url`: GitHub URL for the project
  /// - `closed`: Whether the project is closed
  /// - `createdAt`: Project creation timestamp
  /// - `updatedAt`: Last update timestamp
  ///
  /// Uses GitHub GraphQL API with query:
  /// ```graphql
  /// query GetUserProjects($first: Int!) {
  ///   viewer {
  ///     projectsV2(first: $first) {
  ///       nodes { id, title, shortDescription, url, closed, ... }
  ///     }
  ///   }
  /// }
  /// ```
  ///
  /// Results are cached for 5 minutes using [CacheService].
  ///
  /// Example:
  /// ```dart
  /// final projects = await githubApi.fetchProjects(first: 30);
  /// for (final project in projects) {
  ///   print('${project['title']}: ${project['url']}');
  /// }
  /// ```
  ///
  /// Returns an empty list if the request fails or GraphQL errors occur.
  /// Errors are logged and handled by [AppErrorHandler].
  ///
  /// [first] Maximum number of projects to fetch (default: 30).
  /// Returns a list of project maps.
  Future<List<Map<String, dynamic>>> fetchProjects({int first = 30}) async {
    try {
      // Check cache first
      final cacheKey = 'projects_$first';
      final cachedProjects = _cache.get<List>(cacheKey);
      if (cachedProjects != null) {
        debugPrint('Cache hit for projects');
        return cachedProjects.cast<Map<String, dynamic>>();
      }

      debugPrint('Fetching Projects v2...');
      final headers = await _headers;

      // Use GraphQL to fetch Projects v2
      const query = r'''
        query GetUserProjects($first: Int!) {
          viewer {
            projectsV2(first: $first) {
              totalCount
              nodes {
                id
                title
                shortDescription
                url
                closed
                createdAt
                updatedAt
              }
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse('https://api.github.com/graphql'),
            headers: headers,
            body: json.encode({
              'query': query,
              'variables': {'first': first},
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Projects GraphQL response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return [];
        }

        final projects =
            data['data']?['viewer']?['projectsV2']?['nodes'] as List? ?? [];
        debugPrint('Fetched ${projects.length} projects');

        // Cache the result for 5 minutes
        await _cache.set(cacheKey, projects, ttl: const Duration(minutes: 5));

        return projects.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch projects: ${response.statusCode}');
        return [];
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return [];
    }
  }

  /// Move project item between columns (drag-and-drop)
  /// Returns true if successful
  Future<bool> moveProjectItem({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String optionId,
  }) async {
    try {
      debugPrint('Moving project item: $itemId to column $optionId');
      final headers = await _headers;

      const mutation = r'''
        mutation UpdateProjectV2ItemFieldValue(
          $projectId: ID!
          $itemId: ID!
          $fieldId: ID!
          $optionId: String!
        ) {
          updateProjectV2ItemFieldValue(
            input: {
              projectId: $projectId
              itemId: $itemId
              fieldId: $fieldId
              value: { singleSelectOptionId: $optionId }
            }
          ) {
            projectV2Item {
              id
              updatedAt
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse('https://api.github.com/graphql'),
            headers: headers,
            body: json.encode({
              'query': mutation,
              'variables': {
                'projectId': projectId,
                'itemId': itemId,
                'fieldId': fieldId,
                'optionId': optionId,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('Move item GraphQL response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for errors
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          throw Exception(
            'Failed to move item: ${data['errors'][0]['message']}',
          );
        }

        // Check if mutation succeeded
        final result = data['data']?['updateProjectV2ItemFieldValue'];
        if (result != null) {
          debugPrint('✓ Item moved successfully');
          return true;
        } else {
          throw Exception('Mutation returned null');
        }
      } else {
        throw Exception('Failed to move item: HTTP ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return false;
    }
  }

  /// Get project fields (including Status field with columns)
  /// Returns list of field maps, or null on error
  Future<List?> getProjectFields(String projectId) async {
    try {
      debugPrint('Fetching project fields for: $projectId');
      final headers = await _headers;

      const query = r'''
        query GetProjectFields($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              fields(first: 10) {
                nodes {
                  ... on ProjectV2Field {
                    id
                    name
                    dataType
                  }
                  ... on ProjectV2SingleSelectField {
                    id
                    name
                    dataType
                    options {
                      id
                      name
                      color
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse('https://api.github.com/graphql'),
            headers: headers,
            body: json.encode({
              'query': query,
              'variables': {'projectId': projectId},
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return null;
        }

        final fields = data['data']?['node']?['fields']?['nodes'];
        debugPrint('Fetched ${fields?.length ?? 0} project fields');
        return fields;
      } else {
        return null;
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Add an issue to a project using GraphQL mutation
  /// Returns the project item ID if successful, null otherwise
  Future<String?> addProjectItem({
    required String projectId,
    required String issueNodeId,
  }) async {
    try {
      debugPrint('Adding issue $issueNodeId to project $projectId');
      final headers = await _headers;

      const mutation = r'''
        mutation AddProjectV2ItemById(
          $projectId: ID!
          $contentId: ID!
        ) {
          addProjectV2ItemById(
            input: {
              projectId: $projectId
              contentId: $contentId
            }
          ) {
            item {
              id
              content {
                ... on Issue {
                  id
                  number
                  title
                }
              }
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse('https://api.github.com/graphql'),
            headers: headers,
            body: json.encode({
              'query': mutation,
              'variables': {'projectId': projectId, 'contentId': issueNodeId},
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'Add project item GraphQL response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for errors
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return null;
        }

        // Get the item ID
        final result = data['data']?['addProjectV2ItemById']?['item'];
        if (result != null) {
          final itemId = result['id'] as String?;
          debugPrint('✓ Item added to project with ID: $itemId');
          return itemId;
        } else {
          debugPrint('✗ Mutation returned null');
          return null;
        }
      } else {
        debugPrint('✗ Failed to add item: HTTP ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return null;
    }
  }

  /// Get project items (issues) with their status field values
  /// Returns a map of column name -> list of issues
  Future<Map<String, List<Map<String, dynamic>>>> getProjectItems({
    required String projectId,
    required String statusFieldId,
    int first = 100,
  }) async {
    try {
      debugPrint('Fetching project items for project $projectId');
      final headers = await _headers;

      const query = r'''
        query GetProjectItems($projectId: ID!, $first: Int!, $statusFieldId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              items(first: $first) {
                nodes {
                  id
                  createdAt
                  updatedAt
                  content {
                    ... on Issue {
                      id
                      number
                      title
                      body
                      state
                      createdAt
                      updatedAt
                      url
                      assignee {
                        login
                        avatarUrl
                      }
                      labels(first: 10) {
                        nodes {
                          id
                          name
                          color
                        }
                      }
                    }
                  }
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        field {
                          id
                        }
                        optionId
                        name
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final response = await http
          .post(
            Uri.parse('https://api.github.com/graphql'),
            headers: headers,
            body: json.encode({
              'query': query,
              'variables': {
                'projectId': projectId,
                'first': first,
                'statusFieldId': statusFieldId,
              },
            }),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint(
        'Get project items GraphQL response status: ${response.statusCode}',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check for errors
        if (data['errors'] != null) {
          debugPrint('GraphQL errors: ${data['errors']}');
          return {};
        }

        final items = data['data']?['node']?['items']?['nodes'] as List? ?? [];
        debugPrint('Fetched ${items.length} project items');

        // Group items by status column
        final columnItems = <String, List<Map<String, dynamic>>>{};

        for (final item in items) {
          // Get the content (issue)
          final content = item['content'] as Map<String, dynamic>?;
          if (content == null) continue;

          // Find the status field value
          String columnName = 'Todo'; // Default column
          final fieldValues = item['fieldValues']?['nodes'] as List? ?? [];
          for (final fv in fieldValues) {
            if (fv['field']?['id'] == statusFieldId) {
              columnName = fv['name'] as String? ?? 'Todo';
              break;
            }
          }

          // Add to the appropriate column
          if (!columnItems.containsKey(columnName)) {
            columnItems[columnName] = [];
          }
          columnItems[columnName]!.add(content);
        }

        return columnItems;
      } else {
        debugPrint(
          '✗ Failed to get project items: HTTP ${response.statusCode}',
        );
        return {};
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      return {};
    }
  }

  /// Parse repository JSON
  RepoItem _parseRepo(Map<String, dynamic> json) {
    return RepoItem(
      id: json['node_id'] as String,
      title: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
      children: [], // Will be populated separately
    );
  }

  /// Parse issue JSON
  IssueItem _parseIssue(Map<String, dynamic> json) {
    return IssueItem(
      id: json['node_id'] as String,
      title: json['title'] as String,
      number: json['number'] as int,
      bodyMarkdown: json['body'] as String?,
      status: json['state'] == 'open' ? ItemStatus.open : ItemStatus.closed,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      assigneeLogin: json['assignee']?['login'] as String?,
      // PERFORMANCE OPTIMIZATION (Task 16.2): Cache avatar URL for image caching
      assigneeAvatarUrl: json['assignee']?['avatar_url'] as String?,
      labels:
          (json['labels'] as List?)?.map((l) => l['name'] as String).toList() ??
          [],
      isLocalOnly: false,
    );
  }
}

@Riverpod(keepAlive: true)
GitHubApiService githubApiService(Ref ref) {
  return GitHubApiService();
}
