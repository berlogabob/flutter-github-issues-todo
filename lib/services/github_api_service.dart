import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'secure_storage_service.dart';
import 'cache_service.dart';
import 'github_dio_client.dart';
import 'local_storage_service.dart';
import '../utils/app_error_handler.dart';
import '../models/repo_item.dart';
import '../models/issue_item.dart';
import '../models/item.dart';
import '../models/project_item.dart';

/// GitHub REST API Service
class GitHubApiService {
  String? _token;
  final Dio _dio = GitHubDioClient.instance;
  final CacheService _cache = CacheService();
  final LocalStorageService _localStorage = LocalStorageService();

  /// Callback for authentication errors (401/403)
  /// Called when API detects invalid/expired token
  static Function(BuildContext context, String message)? onAuthError;

  GitHubApiService({GitHubApiService? githubApi}) {
    // Allow passing instance for inheritance
    if (githubApi != null) {
      _token = githubApi._token;
    }
  }

  /// Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  Future<void> _invalidateIssueListCaches(
    String owner,
    String repo, {
    required String reason,
  }) async {
    final keys = <String>[
      'issues_${owner}_${repo}_all',
      'issues_${owner}_${repo}_open',
      'issues_${owner}_${repo}_closed',
    ];

    for (final key in keys) {
      await _cache.invalidate(key, reason: reason);
    }
  }

  /// Get stored token using singleton
  Future<String?> getToken({bool forceRefresh = false}) async {
    if (forceRefresh) {
      _token = null; // Clear cache
    }
    _token ??= await SecureStorageService.getToken();
    return _token;
  }

  /// Clear cached token (call on logout)
  void clearCachedToken() {
    _token = null;
    debugPrint('GitHubApiService: Token cache cleared');
  }

  /// Execute request with retry logic (exponential backoff).
  /// Retries on retriable network errors and 5xx server errors.
  Future<Response<dynamic>> _executeWithRetry(
    Future<Response<dynamic>> Function() request, {
    String operation = 'request',
  }) async {
    int retryCount = 0;
    Duration delay = _initialRetryDelay;

    while (true) {
      try {
        final response = await request();
        final statusCode = response.statusCode ?? 0;

        // Retry server errors (5xx)
        if (statusCode >= 500 && statusCode < 600) {
          if (retryCount < _maxRetries) {
            retryCount++;
            debugPrint(
              'GitHubApiService: $operation failed with $statusCode, retrying ($retryCount/$_maxRetries)...',
            );
            await Future.delayed(delay);
            delay *= 2; // Exponential backoff
            continue;
          }
        }

        return response;
      } on DioException catch (e) {
        if (_isRetriableDioError(e) && retryCount < _maxRetries) {
          retryCount++;
          debugPrint(
            'GitHubApiService: $operation failed (${e.type}), retrying ($retryCount/$_maxRetries): ${e.message}',
          );
          await Future.delayed(delay);
          delay *= 2;
        } else {
          debugPrint(
            'GitHubApiService: $operation failed after $retryCount retries',
          );
          rethrow;
        }
      }
    }
  }

  bool _isRetriableDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    if (e.type == DioExceptionType.unknown && e.error is SocketException) {
      return true;
    }
    return false;
  }

  bool _isNetworkOrTimeoutError(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return true;
    }
    if (error is DioException) {
      return _isRetriableDioError(error);
    }
    return error.toString().contains('SocketException') ||
        error.toString().contains('Network') ||
        error.toString().contains('TimeoutException') ||
        error.toString().contains('timed out');
  }

  dynamic _decodedBody(dynamic data) {
    if (data is String) {
      return json.decode(data);
    }
    return data;
  }

  /// Get authentication headers
  Future<Map<String, String>> get _headers async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No authentication token. Please login again.');
    }

    final headers = {
      'Authorization': 'token $token',
      'Accept': 'application/vnd.github.v3+json',
      'User-Agent': 'GitDoIt-App',
    };

    return headers;
  }

  /// Test if token is valid (no network required for this test)
  Future<bool> testTokenSaved() async {
    final token = await getToken();
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
      final cachedRepos = await _cache.getAsync<List>(cacheKey);
      if (cachedRepos != null) {
        debugPrint('Cache hit for repositories (page $page)');
        return cachedRepos
            .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final headers = await _headers;
      debugPrint('Making API call to GitHub...');

      final path = '/user/repos';
      debugPrint('Request path: $path');

      // Execute with retry logic
      final response = await _executeWithRetry(
        () => _dio.get<dynamic>(
          path,
          queryParameters: {
            'sort': 'updated',
            'per_page': perPage,
            'page': page,
          },
          options: Options(headers: headers),
        ),
        operation: 'fetchMyRepositories',
      );

      final statusCode = response.statusCode ?? 0;
      debugPrint('GitHub API response status: $statusCode');

      if (statusCode == 200) {
        final List<dynamic> data = _decodedBody(response.data) as List<dynamic>;
        debugPrint('Parsed ${data.length} repositories');
        final repos = data.map((json) => _parseRepo(json)).toList();

        // PERFORMANCE: Cache the result for 5 minutes
        await _cache.set(
          cacheKey,
          repos.map((r) => r.toJson()).toList(),
          ttl: const Duration(minutes: 5),
        );

        // Also save to persistent storage for offline fallback
        try {
          await _localStorage.saveRepos(repos.map((r) => r.toJson()).toList());
        } catch (e) {
          debugPrint('Failed to save repos to persistent storage: $e');
        }

        return repos;
      } else if (statusCode == 401) {
        debugPrint('401 Unauthorized - Token invalid or expired');
        // Trigger auth error handler if callback is set
        final errorMsg =
            'Invalid GitHub token. Please check your token and try again.';
        debugPrint('GitHubApiService: 401 error - $errorMsg');
        throw Exception(errorMsg);
      } else if (statusCode == 403) {
        debugPrint('403 Forbidden - API rate limit or permissions issue');
        // Trigger auth error handler if callback is set
        final errorMsg =
            'Access forbidden. Check token permissions (needs repo scope).';
        debugPrint('GitHubApiService: 403 error - $errorMsg');
        throw Exception(errorMsg);
      } else {
        debugPrint('Unexpected status code: $statusCode');
        throw Exception('Failed to fetch repositories: $statusCode');
      }
    } on TimeoutException catch (e) {
      // Try to return cached data on timeout
      final reposCacheKey = 'repos_page_$page';
      final cachedData = await _cache.getAsync<List>(reposCacheKey);
      if (cachedData != null) {
        debugPrint('Returning cached repos due to timeout');
        return cachedData
            .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Try persistent storage as fallback for repos
      try {
        final persistentRepos = await _localStorage.getRepos();
        if (persistentRepos.isNotEmpty) {
          debugPrint('Returning persistent storage repos due to timeout');
          return persistentRepos.map((r) => RepoItem.fromJson(r)).toList();
        }
      } catch (persistError) {
        debugPrint('Persistent storage fallback failed: $persistError');
      }

      debugPrint('Request timeout: $e');
      throw Exception('Request timeout. Check your internet connection.');
    } on SocketException catch (e) {
      // Try to return cached data on socket exception
      final reposCacheKey = 'repos_page_$page';
      final cachedData = await _cache.getAsync<List>(reposCacheKey);
      if (cachedData != null) {
        debugPrint('Returning cached repos due to socket exception');
        return cachedData
            .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Try persistent storage as fallback for repos
      try {
        final persistentRepos = await _localStorage.getRepos();
        if (persistentRepos.isNotEmpty) {
          debugPrint(
            'Returning persistent storage repos due to socket exception',
          );
          return persistentRepos.map((r) => RepoItem.fromJson(r)).toList();
        }
      } catch (persistError) {
        debugPrint('Persistent storage fallback failed: $persistError');
      }

      debugPrint('SocketException: $e');
      throw Exception(
        'No internet connection. Please check your network settings.\n\nDetails: ${e.message}',
      );
    } on DioException catch (e) {
      if (_isRetriableDioError(e)) {
        final reposCacheKey = 'repos_page_$page';
        final cachedData = await _cache.getAsync<List>(reposCacheKey);
        if (cachedData != null) {
          debugPrint('Returning cached repos due to Dio network error');
          return cachedData
              .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        try {
          final persistentRepos = await _localStorage.getRepos();
          if (persistentRepos.isNotEmpty) {
            debugPrint(
              'Returning persistent storage repos due to Dio network error',
            );
            return persistentRepos.map((r) => RepoItem.fromJson(r)).toList();
          }
        } catch (persistError) {
          debugPrint('Persistent storage fallback failed: $persistError');
        }
      }
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw Exception(
          'Invalid GitHub token. Please check your token and try again.',
        );
      }
      if (statusCode == 403) {
        throw Exception(
          'Access forbidden. Check token permissions (needs repo scope).',
        );
      }
      throw Exception(
        'Network error: Cannot reach GitHub. Check your internet connection.\n\nDetails: ${e.message}',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Network') ||
          e.toString().contains('failed host lookup')) {
        // Try to return cached data
        final reposCacheKey = 'repos_page_$page';
        final cachedData = await _cache.getAsync<List>(reposCacheKey);
        if (cachedData != null) {
          debugPrint('Returning cached repos due to network error');
          return cachedData
              .map((json) => RepoItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Try persistent storage as fallback for repos
        try {
          final persistentRepos = await _localStorage.getRepos();
          if (persistentRepos.isNotEmpty) {
            debugPrint(
              'Returning persistent storage repos due to network error',
            );
            return persistentRepos.map((r) => RepoItem.fromJson(r)).toList();
          }
        } catch (persistError) {
          debugPrint('Persistent storage fallback failed: $persistError');
        }

        throw Exception(
          'Cannot connect to GitHub. Check your internet connection.\n\nError: ${e.toString()}',
        );
      }
      throw Exception('Unexpected error: ${e.toString()}');
    }
  }

  /// Fetch a single repository by owner/repo name
  /// Does not require authentication for public repos
  Future<RepoItem?> fetchRepoByUrl(String owner, String repo) async {
    try {
      debugPrint('fetchRepoByUrl() called - $owner/$repo');

      final headers = await _headers;
      final uri = Uri.parse('https://api.github.com/repos/$owner/$repo');

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final repoItem = _parseRepo(data);
        debugPrint('Successfully fetched repo: $owner/$repo');
        return repoItem;
      } else if (response.statusCode == 404) {
        debugPrint('Repository not found: $owner/$repo');
        return null;
      } else {
        debugPrint('Failed to fetch repo: ${response.statusCode}');
        return null;
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      debugPrint('Error fetching repo by URL: $e');
      return null;
    }
  }

  /// Check if more repositories are available for pagination
  ///
  /// PERFORMANCE OPTIMIZATION (Task 16.1):
  /// - Fetches one extra item to determine if more pages exist
  /// - Returns true if the response has perPage items (meaning more may exist)
  Future<bool> hasMoreRepositories({int page = 1, int perPage = 30}) async {
    try {
      final headers = await _headers;

      final response = await _executeWithRetry(
        () => _dio.get<dynamic>(
          '/user/repos',
          queryParameters: {
            'sort': 'updated',
            'per_page': perPage,
            'page': page,
          },
          options: Options(headers: headers),
        ),
        operation: 'hasMoreRepositories',
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200) {
        final List<dynamic> data = _decodedBody(response.data) as List<dynamic>;
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
  /// FIX (#25): Changed default state to 'all' to support filtering by closed/open
  Future<List<IssueItem>> fetchIssues(
    String owner,
    String repo, {
    String state = 'all', // Changed from 'open' to 'all' for filter support
  }) async {
    try {
      // FIX (#25): Invalidate old cache entries that used state='open'
      // This ensures users get fresh data with both open and closed issues
      final oldCacheKey = 'issues_${owner}_${repo}_open';
      await _cache.invalidate(oldCacheKey, reason: 'FIX #25: Fetch all issues');

      // Check cache first (with new 'all' state key)
      final cacheKey = 'issues_${owner}_${repo}_$state';
      final cachedIssues = await _cache.getAsync<List>(cacheKey);
      if (cachedIssues != null) {
        debugPrint('Cache hit for issues: $owner/$repo');
        return cachedIssues
            .map((json) => IssueItem.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      final headers = await _headers;

      final response = await _executeWithRetry(
        () => _dio.get<dynamic>(
          '/repos/$owner/$repo/issues',
          queryParameters: {'state': state, 'per_page': 50},
          options: Options(headers: headers),
        ),
        operation: 'fetchIssues',
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200) {
        final List<dynamic> data = _decodedBody(response.data) as List<dynamic>;
        final issues = data.map((json) => _parseIssue(json)).toList();

        // Cache the result for 5 minutes
        await _cache.set(
          cacheKey,
          issues.map((i) => i.toJson()).toList(),
          ttl: const Duration(minutes: 5),
        );

        // Also save to persistent storage for offline fallback
        try {
          await _localStorage.saveSyncedIssues('$owner/$repo', issues);
        } catch (e) {
          debugPrint('Failed to save issues to persistent storage: $e');
        }

        return issues;
      } else {
        throw Exception('Failed to fetch issues');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      // Try to return cached data on network failure
      if (_isNetworkOrTimeoutError(e)) {
        debugPrint('Network error, trying to return cached data for issues');

        // Build cache key for this request
        final issuesCacheKey = 'issues_${owner}_${repo}_$state';

        // Try cache first
        final cachedData = await _cache.getAsync<List>(issuesCacheKey);
        if (cachedData != null) {
          debugPrint('Returning cached issues due to network error');
          return cachedData
              .map((json) => IssueItem.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Try persistent storage as fallback
        try {
          final localStorage = LocalStorageService();
          final persistentIssues = await localStorage.getSyncedIssues(
            '$owner/$repo',
          );
          if (persistentIssues.isNotEmpty) {
            debugPrint(
              'Returning persistent storage issues due to network error',
            );
            return persistentIssues;
          }
        } catch (persistError) {
          debugPrint('Persistent storage fallback failed: $persistError');
        }

        // Only throw if no cached data available
        throw Exception('No internet connection and no cached data available.');
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

      final response = await _dio.get<dynamic>(
        '/repos/$owner/$repo/issues/$issueNumber',
        options: Options(headers: headers),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode == 200) {
        return _parseIssue(_decodedBody(response.data) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to fetch issue: HTTP $statusCode');
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (_isNetworkOrTimeoutError(e)) {
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
        () => _dio.post<dynamic>(
          '/repos/$owner/$repo/issues',
          data: requestBody,
          options: Options(headers: headers),
        ),
        operation: 'createIssue',
      );

      final statusCode = response.statusCode ?? 0;
      debugPrint('Create issue response status: $statusCode');

      if (statusCode == 201) {
        final createdIssue = _parseIssue(
          _decodedBody(response.data) as Map<String, dynamic>,
        );
        await _invalidateIssueListCaches(
          owner,
          repo,
          reason: 'createIssue mutation',
        );
        await _localStorage.upsertSyncedIssue('$owner/$repo', createdIssue);
        return createdIssue;
      } else if (statusCode == 422) {
        final errorBody = _decodedBody(response.data) as Map<String, dynamic>;
        final errors = errorBody['errors'] as List?;
        final errorMsg =
            errors?.map((e) => e['message'] as String).join(', ') ??
            'Unknown error';
        throw Exception('Failed to create issue (422): $errorMsg');
      } else {
        final errorBody = _decodedBody(response.data) as Map<String, dynamic>;
        throw Exception(
          'Failed to create issue: ${errorBody['message'] ?? 'HTTP $statusCode'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (_isNetworkOrTimeoutError(e)) {
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
        () => _dio.patch<dynamic>(
          '/repos/$owner/$repo/issues/$number',
          data: requestBody,
          options: Options(headers: headers),
        ),
        operation: 'updateIssue',
      );

      final statusCode = response.statusCode ?? 0;
      debugPrint('Update issue response status: $statusCode');

      if (statusCode == 200) {
        final updatedIssue = _parseIssue(
          _decodedBody(response.data) as Map<String, dynamic>,
        );
        await _invalidateIssueListCaches(
          owner,
          repo,
          reason: 'updateIssue mutation',
        );
        await _localStorage.upsertSyncedIssue('$owner/$repo', updatedIssue);
        debugPrint('✓ Issue #$number updated successfully');
        return updatedIssue;
      } else {
        final errorBody = _decodedBody(response.data) as Map<String, dynamic>;
        throw Exception(
          'Failed to update issue: ${errorBody['message'] ?? 'HTTP $statusCode'}',
        );
      }
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);

      if (_isNetworkOrTimeoutError(e)) {
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
  /// CACHING (Task 19.2):
  /// - Caches results for 5 minutes to improve performance
  /// - Cache key: `labels_${owner}_${repo}`
  /// - Falls back to network on cache miss or error
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
      // Check cache first (Task 19.2)
      final cacheKey = 'labels_${owner}_$repo';
      final cachedLabels = await _cache.getAsync<List>(cacheKey);
      if (cachedLabels != null) {
        debugPrint('Cache HIT for labels: $owner/$repo');
        return cachedLabels
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }
      debugPrint('Cache MISS for labels: $owner/$repo - fetching from network');

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

        // Cache the result for 5 minutes (Task 19.2)
        await _cache.set(cacheKey, labelsData, ttl: const Duration(minutes: 5));

        return labelsData.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to fetch labels: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('HTTP ClientException fetching labels: $e');
      throw Exception(
        'Network error: Cannot reach GitHub. Check your internet connection.\n\nDetails: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('Request timeout fetching labels: $e');
      throw Exception('Request timeout. Check your internet connection.');
    } on SocketException catch (e) {
      debugPrint('SocketException fetching labels: $e');
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
  /// CACHING (Task 19.2):
  /// - Caches results for 5 minutes to improve performance
  /// - Cache key: `collaborators_${owner}_${repo}`
  /// - Falls back to network on cache miss or error
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
      // Check cache first (Task 19.2)
      final cacheKey = 'collaborators_${owner}_$repo';
      final cachedCollaborators = await _cache.getAsync<List>(cacheKey);
      if (cachedCollaborators != null) {
        debugPrint('Cache HIT for collaborators: $owner/$repo');
        return cachedCollaborators
            .map((json) => json as Map<String, dynamic>)
            .toList();
      }
      debugPrint(
        'Cache MISS for collaborators: $owner/$repo - fetching from network',
      );

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

        // Cache the result for 5 minutes (Task 19.2)
        await _cache.set(
          cacheKey,
          collaboratorsData,
          ttl: const Duration(minutes: 5),
        );

        return collaboratorsData.cast<Map<String, dynamic>>();
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
          'Failed to fetch collaborators: ${errorBody['message'] ?? 'HTTP ${response.statusCode}'}',
        );
      }
    } on http.ClientException catch (e) {
      debugPrint('HTTP ClientException fetching collaborators: $e');
      throw Exception(
        'Network error: Cannot reach GitHub. Check your internet connection.\n\nDetails: ${e.message}',
      );
    } on TimeoutException catch (e) {
      debugPrint('Request timeout fetching collaborators: $e');
      throw Exception('Request timeout. Check your internet connection.');
    } on SocketException catch (e) {
      debugPrint('SocketException fetching collaborators: $e');
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
  /// Throws [Exception] with user-safe messages on auth/network failures.
  /// All errors are logged via [AppErrorHandler] before being rethrown.
  ///
  /// Returns a map of user data.
  Future<Map<String, dynamic>?> getCurrentUser() async {
    try {
      final headers = await _headers;
      final response = await http
          .get(Uri.parse('https://api.github.com/user'), headers: headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception(
          'Authentication failed. Your session may have expired. Please login again.',
        );
      } else if (response.statusCode == 403) {
        throw Exception(
          'Access denied. Check your GitHub token permissions and try again.',
        );
      }
      throw Exception(
        'Unable to fetch user profile right now. Please try again later.',
      );
    } catch (e, stackTrace) {
      AppErrorHandler.handle(e, stackTrace: stackTrace);
      if (_isNetworkOrTimeoutError(e)) {
        throw Exception(
          'Cannot connect to GitHub. Check your internet connection and try again.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _graphQl(
    String document, [
    Map<String, dynamic> variables = const {},
  ]) async {
    final response = await http
        .post(
          Uri.parse('https://api.github.com/graphql'),
          headers: await _headers,
          body: json.encode({'query': document, 'variables': variables}),
        )
        .timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub GraphQL request failed: HTTP ${response.statusCode}',
      );
    }

    final decoded = json.decode(response.body) as Map<String, dynamic>;
    final errors = decoded['errors'] as List?;
    if (errors != null && errors.isNotEmpty) {
      final message = errors
          .map(
            (error) => (error as Map)['message']?.toString() ?? 'Unknown error',
          )
          .join('; ');
      throw Exception('GitHub GraphQL error: $message');
    }

    return Map<String, dynamic>.from(decoded['data'] as Map? ?? const {});
  }

  /// Fetch all visible personal and organization Projects V2.
  Future<List<ProjectV2>> fetchProjectsFromGitHub() async {
    const personalQuery = r'''
      query Projects($after: String) {
        viewer {
          login
          projectsV2(first: 100, after: $after) {
            nodes {
              id number title shortDescription url closed updatedAt
              viewerCanUpdate
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    ''';
    const organizationsQuery = r'''
      query Organizations($after: String) {
        viewer {
          organizations(first: 100, after: $after) {
            nodes { login }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    ''';
    const organizationProjectsQuery = r'''
      query OrganizationProjects($login: String!, $after: String) {
        organization(login: $login) {
          projectsV2(first: 100, after: $after, minPermissionLevel: READ) {
            nodes {
              id number title shortDescription url closed updatedAt
              viewerCanUpdate
            }
            pageInfo { hasNextPage endCursor }
          }
        }
      }
    ''';

    final projects = <ProjectV2>[];
    String? cursor;
    String viewerLogin = 'me';
    do {
      final data = await _graphQl(personalQuery, {'after': cursor});
      final viewer = Map<String, dynamic>.from(data['viewer'] as Map);
      viewerLogin = viewer['login'] as String? ?? viewerLogin;
      final connection = Map<String, dynamic>.from(
        viewer['projectsV2'] as Map? ?? const {},
      );
      projects.addAll(
        _parseProjects(
          connection['nodes'] as List? ?? const [],
          viewerLogin,
          ProjectOwnerType.user,
        ),
      );
      cursor = _nextCursor(connection);
    } while (cursor != null);

    final organizations = <String>[];
    cursor = null;
    do {
      final data = await _graphQl(organizationsQuery, {'after': cursor});
      final viewer = Map<String, dynamic>.from(data['viewer'] as Map);
      final connection = Map<String, dynamic>.from(
        viewer['organizations'] as Map? ?? const {},
      );
      organizations.addAll(
        (connection['nodes'] as List? ?? const []).map(
          (node) => (node as Map)['login'] as String,
        ),
      );
      cursor = _nextCursor(connection);
    } while (cursor != null);

    for (final organization in organizations) {
      cursor = null;
      do {
        final data = await _graphQl(organizationProjectsQuery, {
          'login': organization,
          'after': cursor,
        });
        final owner = data['organization'] as Map?;
        if (owner == null) break;
        final connection = Map<String, dynamic>.from(
          owner['projectsV2'] as Map? ?? const {},
        );
        projects.addAll(
          _parseProjects(
            connection['nodes'] as List? ?? const [],
            organization,
            ProjectOwnerType.organization,
          ),
        );
        cursor = _nextCursor(connection);
      } while (cursor != null);
    }

    final byId = <String, ProjectV2>{
      for (final project in projects) project.id: project,
    };
    final result = byId.values.toList()
      ..sort((a, b) {
        if (a.closed != b.closed) return a.closed ? 1 : -1;
        return a.displayName.toLowerCase().compareTo(
          b.displayName.toLowerCase(),
        );
      });
    return result;
  }

  List<ProjectV2> _parseProjects(
    List<dynamic> nodes,
    String ownerLogin,
    ProjectOwnerType ownerType,
  ) {
    return nodes.map((raw) {
      final node = Map<String, dynamic>.from(raw as Map);
      return ProjectV2(
        id: node['id'] as String,
        number: node['number'] as int? ?? 0,
        title: node['title'] as String? ?? 'Untitled project',
        ownerLogin: ownerLogin,
        ownerType: ownerType,
        url: node['url'] as String? ?? '',
        shortDescription: node['shortDescription'] as String?,
        closed: node['closed'] as bool? ?? false,
        viewerCanUpdate: node['viewerCanUpdate'] as bool? ?? false,
        updatedAt: DateTime.tryParse(node['updatedAt'] as String? ?? ''),
      );
    }).toList();
  }

  String? _nextCursor(Map<String, dynamic> connection) {
    final pageInfo = connection['pageInfo'] as Map?;
    if (pageInfo?['hasNextPage'] != true) return null;
    return pageInfo?['endCursor'] as String?;
  }

  /// Fetch a complete board snapshot, following every item page.
  Future<ProjectV2Board> fetchProjectBoardFromGitHub(ProjectV2 project) async {
    const query = r'''
      query ProjectBoard($projectId: ID!, $after: String) {
        node(id: $projectId) {
          ... on ProjectV2 {
            title shortDescription url closed updatedAt viewerCanUpdate
            fields(first: 100) {
              nodes {
                __typename
                ... on ProjectV2SingleSelectField {
                  id name dataType
                  options { id name color }
                }
              }
            }
            items(first: 100, after: $after) {
              nodes {
                id type updatedAt
                fieldValues(first: 100) {
                  nodes {
                    ... on ProjectV2ItemFieldSingleSelectValue {
                      optionId name
                      field { ... on ProjectV2FieldCommon { id name } }
                    }
                  }
                }
                content {
                  __typename
                  ... on Issue {
                    id number title body state url updatedAt
                    repository { nameWithOwner }
                    assignees(first: 1) { nodes { login avatarUrl } }
                    labels(first: 10) { nodes { name } }
                  }
                  ... on PullRequest {
                    id number title body state url updatedAt
                    repository { nameWithOwner }
                    assignees(first: 1) { nodes { login avatarUrl } }
                    labels(first: 10) { nodes { name } }
                  }
                  ... on DraftIssue {
                    id title body updatedAt
                    assignees(first: 1) { nodes { login avatarUrl } }
                  }
                }
              }
              pageInfo { hasNextPage endCursor }
            }
          }
        }
      }
    ''';

    final items = <ProjectV2BoardItem>[];
    List<ProjectV2Column> columns = const [];
    String? statusFieldId;
    ProjectV2 currentProject = project;
    String? cursor;

    do {
      final data = await _graphQl(query, {
        'projectId': project.id,
        'after': cursor,
      });
      final node = data['node'] as Map?;
      if (node == null) {
        throw Exception('Project not found or no longer accessible');
      }
      final projectNode = Map<String, dynamic>.from(node);
      currentProject = ProjectV2(
        id: project.id,
        number: project.number,
        title: projectNode['title'] as String? ?? project.title,
        ownerLogin: project.ownerLogin,
        ownerType: project.ownerType,
        url: projectNode['url'] as String? ?? project.url,
        shortDescription: projectNode['shortDescription'] as String?,
        closed: projectNode['closed'] as bool? ?? project.closed,
        viewerCanUpdate:
            projectNode['viewerCanUpdate'] as bool? ?? project.viewerCanUpdate,
        updatedAt: DateTime.tryParse(projectNode['updatedAt'] as String? ?? ''),
      );

      if (statusFieldId == null) {
        final fields =
            (projectNode['fields'] as Map?)?['nodes'] as List? ?? const [];
        for (final rawField in fields) {
          final field = Map<String, dynamic>.from(rawField as Map);
          if (field['__typename'] != 'ProjectV2SingleSelectField' ||
              (field['name'] as String?)?.toLowerCase() != 'status') {
            continue;
          }
          statusFieldId = field['id'] as String;
          columns = [
            ProjectV2Column(
              fieldId: statusFieldId,
              optionId: null,
              name: 'No status',
              color: 'GRAY',
            ),
            ...(field['options'] as List? ?? const []).map((rawOption) {
              final option = Map<String, dynamic>.from(rawOption as Map);
              return ProjectV2Column(
                fieldId: statusFieldId!,
                optionId: option['id'] as String,
                name: option['name'] as String,
                color: option['color'] as String? ?? 'GRAY',
              );
            }),
          ];
          break;
        }
      }

      final connection = Map<String, dynamic>.from(
        projectNode['items'] as Map? ?? const {},
      );
      items.addAll(
        (connection['nodes'] as List? ?? const []).map(
          (rawItem) => _parseProjectBoardItem(
            Map<String, dynamic>.from(rawItem as Map),
            statusFieldId,
          ),
        ),
      );
      cursor = _nextCursor(connection);
    } while (cursor != null);

    return ProjectV2Board(
      project: currentProject,
      statusFieldId: statusFieldId,
      columns: columns,
      items: items,
      fetchedAt: DateTime.now(),
    );
  }

  ProjectV2BoardItem _parseProjectBoardItem(
    Map<String, dynamic> item,
    String? statusFieldId,
  ) {
    final content = item['content'] as Map?;
    final typeName = content?['__typename'] as String?;
    final contentType = switch (typeName) {
      'Issue' => ProjectContentType.issue,
      'PullRequest' => ProjectContentType.pullRequest,
      'DraftIssue' => ProjectContentType.draftIssue,
      _ => ProjectContentType.redacted,
    };

    String? statusOptionId;
    String? statusName;
    final values = (item['fieldValues'] as Map?)?['nodes'] as List? ?? const [];
    for (final rawValue in values) {
      final value = rawValue as Map;
      if (value['field']?['id'] == statusFieldId) {
        statusOptionId = value['optionId'] as String?;
        statusName = value['name'] as String?;
        break;
      }
    }

    final assignees =
        (content?['assignees'] as Map?)?['nodes'] as List? ?? const [];
    final assignee = assignees.isEmpty ? null : assignees.first as Map;
    final labels = (content?['labels'] as Map?)?['nodes'] as List? ?? const [];

    return ProjectV2BoardItem(
      projectItemId: item['id'] as String,
      contentId: content?['id'] as String?,
      contentType: contentType,
      title: content?['title'] as String? ?? 'Unavailable item',
      number: content?['number'] as int?,
      body: content?['body'] as String?,
      state: (content?['state'] as String?)?.toLowerCase(),
      url: content?['url'] as String?,
      repoFullName:
          (content?['repository'] as Map?)?['nameWithOwner'] as String?,
      updatedAt: DateTime.tryParse(
        content?['updatedAt'] as String? ?? item['updatedAt'] as String? ?? '',
      ),
      assigneeLogin: assignee?['login'] as String?,
      assigneeAvatarUrl: assignee?['avatarUrl'] as String?,
      labels: labels.map((label) => (label as Map)['name'] as String).toList(),
      statusOptionId: statusOptionId,
      statusName: statusName,
    );
  }

  Future<void> setProjectItemStatus({
    required String projectId,
    required String itemId,
    required String fieldId,
    required String? optionId,
  }) async {
    if (optionId == null) {
      const mutation = r'''
        mutation ClearStatus($projectId: ID!, $itemId: ID!, $fieldId: ID!) {
          clearProjectV2ItemFieldValue(input: {
            projectId: $projectId itemId: $itemId fieldId: $fieldId
          }) { projectV2Item { id } }
        }
      ''';
      await _graphQl(mutation, {
        'projectId': projectId,
        'itemId': itemId,
        'fieldId': fieldId,
      });
      return;
    }

    const mutation = r'''
      mutation SetStatus(
        $projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!
      ) {
        updateProjectV2ItemFieldValue(input: {
          projectId: $projectId itemId: $itemId fieldId: $fieldId
          value: { singleSelectOptionId: $optionId }
        }) { projectV2Item { id } }
      }
    ''';
    await _graphQl(mutation, {
      'projectId': projectId,
      'itemId': itemId,
      'fieldId': fieldId,
      'optionId': optionId,
    });
  }

  Future<String> addProjectV2Item({
    required String projectId,
    required String contentId,
  }) async {
    const mutation = r'''
      mutation AddItem($projectId: ID!, $contentId: ID!) {
        addProjectV2ItemById(input: {
          projectId: $projectId contentId: $contentId
        }) { item { id } }
      }
    ''';
    final data = await _graphQl(mutation, {
      'projectId': projectId,
      'contentId': contentId,
    });
    final payload = data['addProjectV2ItemById'] as Map?;
    final item = payload?['item'] as Map?;
    final itemId = item?['id'] as String?;
    if (itemId == null) {
      throw Exception('GitHub did not return a project item ID');
    }
    return itemId;
  }

  /// Parse repository JSON
  RepoItem _parseRepo(Map<String, dynamic> json) {
    return RepoItem(
      id: json['node_id'] as String,
      title: json['name'] as String,
      fullName: json['full_name'] as String,
      description: json['description'] as String?,
      openIssuesCount:
          json['open_issues_count'] as int? ??
          0, // FIX (#33): Get open issues count from GitHub
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
