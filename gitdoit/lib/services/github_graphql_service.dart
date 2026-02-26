import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../utils/logging.dart';

/// GitHub GraphQL Service - Projects v2 API operations
///
/// Handles:
/// - Projects v2 queries
/// - Project items mutations
/// - Field updates (Status, Priority, etc.)
/// - OAuth token management
class GitHubGraphQLService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  GraphQLClient? _client;

  // GitHub GraphQL API endpoint
  static const String apiUrl = 'https://api.github.com/graphql';

  // Get authenticated token
  Future<String> get _token async {
    try {
      final token = await _storage.read(key: 'github_token');
      if (token == null || token.isEmpty) {
        throw Exception('No GitHub token found. Please login first.');
      }
      return token;
    } catch (e) {
      Logger.e('Failed to read token from storage', error: e, context: 'GitHub GraphQL');
      throw Exception('No GitHub token found. Please login first.');
    }
  }

  // Initialize GraphQL client
  Future<void> _initializeClient() async {
    if (_client != null) return;

    try {
      final authToken = await _token;

      final httpLink = HttpLink(apiUrl, defaultHeaders: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/vnd.github.v4+json',
        'User-Agent': 'GitDoIt-App',
      });

      _client = GraphQLClient(
        link: httpLink,
        cache: GraphQLCache(),
      );

      Logger.d('GraphQL client initialized', context: 'GitHub GraphQL');
    } catch (e) {
      Logger.e('Failed to initialize GraphQL client', error: e, context: 'GitHub GraphQL');
      rethrow;
    }
  }

  /// Get current user's projects (Projects v2)
  ///
  /// [first] - Number of projects to fetch (default: 10)
  /// [after] - Cursor for pagination
  Future<List<Map<String, dynamic>>> getUserProjects({
    int first = 10,
    String? after,
  }) async {
    final metric = Logger.startMetric('getUserProjects', 'GitHub GraphQL');
    Logger.d('Fetching user projects', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      const query = r'''
        query GetUserProjects($first: Int!, $after: String) {
          viewer {
            projectsV2(first: $first, after: $after) {
              totalCount
              pageInfo {
                hasNextPage
                endCursor
              }
              nodes {
                id
                number
                title
                shortDescription
                url
                closed
                createdAt
                updatedAt
                fields(first: 10) {
                  nodes {
                    ... on ProjectV2FieldCommon {
                      id
                      name
                      dataType
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final result = await _client!.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'first': first,
            'after': after,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to fetch projects', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to fetch projects: ${result.exception}');
      }

      final projectsData = result.data?['viewer']?['projectsV2'] as Map<String, dynamic>?;
      final projects = (projectsData?['nodes'] as List<dynamic>?) ?? [];

      Logger.i('Fetched ${projects.length} projects', context: 'GitHub GraphQL');
      metric.complete(success: true);

      return projects.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      Logger.e('Error fetching projects', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Get project items (issues/PRs in a project)
  ///
  /// [projectId] - The Project V2 ID
  /// [first] - Number of items to fetch
  Future<List<Map<String, dynamic>>> getProjectItems({
    required String projectId,
    int first = 100,
  }) async {
    final metric = Logger.startMetric('getProjectItems', 'GitHub GraphQL');
    Logger.d('Fetching project items for $projectId', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      const query = r'''
        query GetProjectItems($projectId: ID!, $first: Int!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              items(first: $first) {
                nodes {
                  id
                  type
                  createdAt
                  updatedAt
                  fieldValues(first: 10) {
                    nodes {
                      ... on ProjectV2ItemFieldTextValue {
                        field {
                          ... on ProjectV2FieldCommon {
                            id
                            name
                          }
                        }
                        text
                      }
                      ... on ProjectV2ItemFieldNumberValue {
                        field {
                          ... on ProjectV2FieldCommon {
                            id
                            name
                          }
                        }
                        number
                      }
                      ... on ProjectV2ItemFieldSingleSelectValue {
                        field {
                          ... on ProjectV2FieldCommon {
                            id
                            name
                          }
                        }
                        name
                        color
                      }
                      ... on ProjectV2ItemFieldIterationValue {
                        field {
                          ... on ProjectV2FieldCommon {
                            id
                            name
                          }
                        }
                        title
                        startDate
                        duration
                      }
                    }
                  }
                  content {
                    ... on Issue {
                      id
                      number
                      title
                      body
                      state
                      url
                      createdAt
                      updatedAt
                      assignees(first: 5) {
                        nodes {
                          login
                          avatarUrl
                        }
                      }
                      labels(first: 10) {
                        nodes {
                          id
                          name
                          color
                        }
                      }
                      repository {
                        name
                        owner {
                          login
                        }
                      }
                    }
                    ... on PullRequest {
                      id
                      number
                      title
                      body
                      state
                      url
                      createdAt
                      updatedAt
                      assignees(first: 5) {
                        nodes {
                          login
                          avatarUrl
                        }
                      }
                      labels(first: 10) {
                        nodes {
                          id
                          name
                          color
                        }
                      }
                      repository {
                        name
                        owner {
                          login
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      ''';

      final result = await _client!.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'projectId': projectId,
            'first': first,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to fetch project items', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to fetch project items: ${result.exception}');
      }

      final projectData = result.data?['node'] as Map<String, dynamic>?;
      final itemsData = projectData?['items'] as Map<String, dynamic>?;
      final items = (itemsData?['nodes'] as List<dynamic>?) ?? [];

      Logger.i('Fetched ${items.length} project items', context: 'GitHub GraphQL');
      metric.complete(success: true);

      return items.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      Logger.e('Error fetching project items', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Add item to project
  ///
  /// [projectId] - The Project V2 ID
  /// [contentId] - The Issue or PullRequest ID
  Future<Map<String, dynamic>> addProjectItem({
    required String projectId,
    required String contentId,
  }) async {
    final metric = Logger.startMetric('addProjectItem', 'GitHub GraphQL');
    Logger.d('Adding item $contentId to project $projectId', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      const mutation = r'''
        mutation AddProjectItem($projectId: ID!, $contentId: ID!) {
          addProjectV2ItemById(input: {
            projectId: $projectId
            contentId: $contentId
          }) {
            item {
              id
              type
              createdAt
            }
          }
        }
      ''';

      final result = await _client!.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'projectId': projectId,
            'contentId': contentId,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to add project item', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to add project item: ${result.exception}');
      }

      final itemData = result.data?['addProjectV2ItemById']?['item'] as Map<String, dynamic>?;

      Logger.i('Added item to project', context: 'GitHub GraphQL');
      metric.complete(success: true);

      return itemData ?? {};
    } catch (e, stackTrace) {
      Logger.e('Error adding project item', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Update project item field (supports all field types)
  ///
  /// [itemId] - The Project Item ID
  /// [fieldId] - The Field ID
  /// [value] - The new value (type depends on field type)
  /// [fieldType] - The field data type
  Future<void> updateProjectItemField({
    required String itemId,
    required String fieldId,
    required dynamic value,
    String fieldType = 'TEXT',
  }) async {
    final metric = Logger.startMetric('updateProjectItemField', 'GitHub GraphQL');
    Logger.d('Updating item $itemId field $fieldId', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      String valueInput;
      String mutationName;
      
      switch (fieldType) {
        case 'SINGLE_SELECT':
          mutationName = 'UpdateSingleSelectField';
          valueInput = 'singleSelectOptionId: $value';
          break;
        case 'NUMBER':
          mutationName = 'UpdateNumberField';
          valueInput = 'number: $value';
          break;
        case 'TEXT':
          mutationName = 'UpdateTextField';
          valueInput = 'text: "$value"';
          break;
        case 'DATE':
          mutationName = 'UpdateDateField';
          valueInput = 'date: "$value"';
          break;
        case 'ITERATION':
          mutationName = 'UpdateIterationField';
          valueInput = 'iterationId: "$value"';
          break;
        default:
          mutationName = 'UpdateTextField';
          valueInput = 'text: "$value"';
      }

      final mutation = '''
        mutation $mutationName(\$itemId: ID!, \$fieldId: ID!) {
          updateProjectV2ItemFieldValue(input: {
            itemId: \$itemId
            fieldId: \$fieldId
            value: {
              $valueInput
            }
          }) {
            item {
              id
              updatedAt
            }
          }
        }
      ''';

      final result = await _client!.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'itemId': itemId,
            'fieldId': fieldId,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to update project item field', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to update project item field: ${result.exception}');
      }

      Logger.i('Updated project item field', context: 'GitHub GraphQL');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e('Error updating project item field', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Get project fields (columns/custom fields)
  ///
  /// [projectId] - The Project V2 ID
  Future<List<Map<String, dynamic>>> getProjectFields({
    required String projectId,
  }) async {
    final metric = Logger.startMetric('getProjectFields', 'GitHub GraphQL');
    Logger.d('Fetching project fields for $projectId', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      const query = r'''
        query GetProjectFields($projectId: ID!) {
          node(id: $projectId) {
            ... on ProjectV2 {
              fields(first: 50) {
                nodes {
                  ... on ProjectV2FieldCommon {
                    id
                    name
                    dataType
                  }
                  ... on ProjectV2SingleSelectField {
                    id
                    name
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

      final result = await _client!.query(
        QueryOptions(
          document: gql(query),
          variables: {
            'projectId': projectId,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to fetch project fields', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to fetch project fields: ${result.exception}');
      }

      final projectData = result.data?['node'] as Map<String, dynamic>?;
      final fieldsData = projectData?['fields'] as Map<String, dynamic>?;
      final fields = (fieldsData?['nodes'] as List<dynamic>?) ?? [];

      Logger.i('Fetched ${fields.length} project fields', context: 'GitHub GraphQL');
      metric.complete(success: true);

      return fields.cast<Map<String, dynamic>>();
    } catch (e, stackTrace) {
      Logger.e('Error fetching project fields', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Remove item from project
  ///
  /// [projectId] - The Project V2 ID
  /// [itemId] - The Project Item ID
  Future<void> removeProjectItem({
    required String projectId,
    required String itemId,
  }) async {
    final metric = Logger.startMetric('removeProjectItem', 'GitHub GraphQL');
    Logger.d('Removing item $itemId from project $projectId', context: 'GitHub GraphQL');

    try {
      await _initializeClient();

      const mutation = r'''
        mutation RemoveProjectItem($projectId: ID!, $itemId: ID!) {
          deleteProjectV2Item(input: {
            projectId: $projectId
            itemId: $itemId
          }) {
            deletedItemId
          }
        }
      ''';

      final result = await _client!.mutate(
        MutationOptions(
          document: gql(mutation),
          variables: {
            'projectId': projectId,
            'itemId': itemId,
          },
        ),
      );

      if (result.hasException) {
        Logger.e('Failed to remove project item', error: result.exception, context: 'GitHub GraphQL');
        metric.complete(success: false, errorMessage: result.exception.toString());
        throw Exception('Failed to remove project item: ${result.exception}');
      }

      Logger.i('Removed project item', context: 'GitHub GraphQL');
      metric.complete(success: true);
    } catch (e, stackTrace) {
      Logger.e('Error removing project item', error: e, stackTrace: stackTrace, context: 'GitHub GraphQL');
      metric.complete(success: false, errorMessage: e.toString());
      rethrow;
    }
  }

  /// Dispose GraphQL client
  void dispose() {
    _client = null;
    Logger.d('GitHubGraphQLService disposed', context: 'GitHub GraphQL');
  }
}
