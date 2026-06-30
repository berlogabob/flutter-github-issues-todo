enum ProjectOwnerType { user, organization }

enum ProjectContentType { issue, pullRequest, draftIssue, redacted }

enum ProjectItemSyncState { synced, pending, failed }

/// A GitHub Projects V2 project.
class ProjectV2 {
  final String id;
  final int number;
  final String title;
  final String ownerLogin;
  final ProjectOwnerType ownerType;
  final String url;
  final String? shortDescription;
  final bool closed;
  final bool viewerCanUpdate;
  final DateTime? updatedAt;

  const ProjectV2({
    required this.id,
    required this.number,
    required this.title,
    required this.ownerLogin,
    required this.ownerType,
    required this.url,
    this.shortDescription,
    this.closed = false,
    this.viewerCanUpdate = false,
    this.updatedAt,
  });

  String get displayName => '$ownerLogin / $title';

  ProjectV2 copyWith({bool? viewerCanUpdate, DateTime? updatedAt}) {
    return ProjectV2(
      id: id,
      number: number,
      title: title,
      ownerLogin: ownerLogin,
      ownerType: ownerType,
      url: url,
      shortDescription: shortDescription,
      closed: closed,
      viewerCanUpdate: viewerCanUpdate ?? this.viewerCanUpdate,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'number': number,
    'title': title,
    'ownerLogin': ownerLogin,
    'ownerType': ownerType.name,
    'url': url,
    'shortDescription': shortDescription,
    'closed': closed,
    'viewerCanUpdate': viewerCanUpdate,
    'updatedAt': updatedAt?.toIso8601String(),
  };

  factory ProjectV2.fromJson(Map<String, dynamic> json) {
    return ProjectV2(
      id: json['id'] as String,
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? 'Untitled project',
      ownerLogin: json['ownerLogin'] as String? ?? 'unknown',
      ownerType: ProjectOwnerType.values.firstWhere(
        (value) => value.name == json['ownerType'],
        orElse: () => ProjectOwnerType.user,
      ),
      url: json['url'] as String? ?? '',
      shortDescription: json['shortDescription'] as String?,
      closed: json['closed'] as bool? ?? false,
      viewerCanUpdate: json['viewerCanUpdate'] as bool? ?? false,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
    );
  }
}

class ProjectV2Column {
  final String fieldId;
  final String? optionId;
  final String name;
  final String color;

  const ProjectV2Column({
    required this.fieldId,
    required this.optionId,
    required this.name,
    required this.color,
  });

  bool get isUnassigned => optionId == null;

  Map<String, dynamic> toJson() => {
    'fieldId': fieldId,
    'optionId': optionId,
    'name': name,
    'color': color,
  };

  factory ProjectV2Column.fromJson(Map<String, dynamic> json) {
    return ProjectV2Column(
      fieldId: json['fieldId'] as String? ?? '',
      optionId: json['optionId'] as String?,
      name: json['name'] as String? ?? 'No status',
      color: json['color'] as String? ?? 'GRAY',
    );
  }
}

class ProjectV2BoardItem {
  final String projectItemId;
  final String? contentId;
  final ProjectContentType contentType;
  final String title;
  final int? number;
  final String? body;
  final String? state;
  final String? url;
  final String? repoFullName;
  final DateTime? updatedAt;
  final String? assigneeLogin;
  final String? assigneeAvatarUrl;
  final List<String> labels;
  final String? statusOptionId;
  final String? statusName;
  final ProjectItemSyncState syncState;

  const ProjectV2BoardItem({
    required this.projectItemId,
    required this.contentType,
    required this.title,
    this.contentId,
    this.number,
    this.body,
    this.state,
    this.url,
    this.repoFullName,
    this.updatedAt,
    this.assigneeLogin,
    this.assigneeAvatarUrl,
    this.labels = const [],
    this.statusOptionId,
    this.statusName,
    this.syncState = ProjectItemSyncState.synced,
  });

  ProjectV2BoardItem copyWith({
    String? statusOptionId,
    bool clearStatus = false,
    String? statusName,
    ProjectItemSyncState? syncState,
  }) {
    return ProjectV2BoardItem(
      projectItemId: projectItemId,
      contentId: contentId,
      contentType: contentType,
      title: title,
      number: number,
      body: body,
      state: state,
      url: url,
      repoFullName: repoFullName,
      updatedAt: updatedAt,
      assigneeLogin: assigneeLogin,
      assigneeAvatarUrl: assigneeAvatarUrl,
      labels: labels,
      statusOptionId: clearStatus
          ? null
          : statusOptionId ?? this.statusOptionId,
      statusName: clearStatus ? null : statusName ?? this.statusName,
      syncState: syncState ?? this.syncState,
    );
  }

  Map<String, dynamic> toJson() => {
    'projectItemId': projectItemId,
    'contentId': contentId,
    'contentType': contentType.name,
    'title': title,
    'number': number,
    'body': body,
    'state': state,
    'url': url,
    'repoFullName': repoFullName,
    'updatedAt': updatedAt?.toIso8601String(),
    'assigneeLogin': assigneeLogin,
    'assigneeAvatarUrl': assigneeAvatarUrl,
    'labels': labels,
    'statusOptionId': statusOptionId,
    'statusName': statusName,
    'syncState': syncState.name,
  };

  factory ProjectV2BoardItem.fromJson(Map<String, dynamic> json) {
    return ProjectV2BoardItem(
      projectItemId: json['projectItemId'] as String,
      contentId: json['contentId'] as String?,
      contentType: ProjectContentType.values.firstWhere(
        (value) => value.name == json['contentType'],
        orElse: () => ProjectContentType.redacted,
      ),
      title: json['title'] as String? ?? 'Unavailable item',
      number: json['number'] as int?,
      body: json['body'] as String?,
      state: json['state'] as String?,
      url: json['url'] as String?,
      repoFullName: json['repoFullName'] as String?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.tryParse(json['updatedAt'] as String),
      assigneeLogin: json['assigneeLogin'] as String?,
      assigneeAvatarUrl: json['assigneeAvatarUrl'] as String?,
      labels: (json['labels'] as List?)?.cast<String>() ?? const [],
      statusOptionId: json['statusOptionId'] as String?,
      statusName: json['statusName'] as String?,
      syncState: ProjectItemSyncState.values.firstWhere(
        (value) => value.name == json['syncState'],
        orElse: () => ProjectItemSyncState.synced,
      ),
    );
  }
}

class ProjectV2Board {
  final ProjectV2 project;
  final String? statusFieldId;
  final List<ProjectV2Column> columns;
  final List<ProjectV2BoardItem> items;
  final DateTime fetchedAt;

  const ProjectV2Board({
    required this.project,
    required this.statusFieldId,
    required this.columns,
    required this.items,
    required this.fetchedAt,
  });

  ProjectV2Board copyWith({List<ProjectV2BoardItem>? items}) {
    return ProjectV2Board(
      project: project,
      statusFieldId: statusFieldId,
      columns: columns,
      items: items ?? this.items,
      fetchedAt: fetchedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'project': project.toJson(),
    'statusFieldId': statusFieldId,
    'columns': columns.map((column) => column.toJson()).toList(),
    'items': items.map((item) => item.toJson()).toList(),
    'fetchedAt': fetchedAt.toIso8601String(),
  };

  factory ProjectV2Board.fromJson(Map<String, dynamic> json) {
    return ProjectV2Board(
      project: ProjectV2.fromJson(
        Map<String, dynamic>.from(json['project'] as Map),
      ),
      statusFieldId: json['statusFieldId'] as String?,
      columns: (json['columns'] as List? ?? const [])
          .map(
            (column) => ProjectV2Column.fromJson(
              Map<String, dynamic>.from(column as Map),
            ),
          )
          .toList(),
      items: (json['items'] as List? ?? const [])
          .map(
            (item) => ProjectV2BoardItem.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList(),
      fetchedAt:
          DateTime.tryParse(json['fetchedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
