import 'package:json_annotation/json_annotation.dart';

part 'issue.g.dart';

/// GitHub Issue model
///
/// Represents a GitHub Issue with all its properties
@JsonSerializable()
class Issue {
  final int number;
  final String title;
  final String? body;
  final String state; // 'open' or 'closed'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  final List<Label> labels;
  final Milestone? milestone;
  final User? assignee;
  @JsonKey(name: 'assignees')
  final List<User> assignees;
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  @JsonKey(name: 'repository_url')
  final String? repositoryUrl;
  final User? user;

  Issue({
    required this.number,
    required this.title,
    this.body,
    required this.state,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.labels = const [],
    this.milestone,
    this.assignee,
    this.assignees = const [],
    this.htmlUrl,
    this.repositoryUrl,
    this.user,
  });

  factory Issue.fromJson(Map<String, dynamic> json) => _$IssueFromJson(json);
  Map<String, dynamic> toJson() => _$IssueToJson(this);

  /// Check if issue is open
  bool get isOpen => state == 'open';

  /// Check if issue is closed
  bool get isClosed => state == 'closed';

  /// Get formatted title with number
  String get formattedTitle => '#$number - $title';

  /// Copy with method for immutability
  Issue copyWith({
    int? number,
    String? title,
    String? body,
    String? state,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? closedAt,
    List<Label>? labels,
    Milestone? milestone,
    User? assignee,
    List<User>? assignees,
    String? htmlUrl,
    String? repositoryUrl,
    User? user,
  }) {
    return Issue(
      number: number ?? this.number,
      title: title ?? this.title,
      body: body ?? this.body,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: closedAt ?? this.closedAt,
      labels: labels ?? this.labels,
      milestone: milestone ?? this.milestone,
      assignee: assignee ?? this.assignee,
      assignees: assignees ?? this.assignees,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      repositoryUrl: repositoryUrl ?? this.repositoryUrl,
      user: user ?? this.user,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Issue &&
        other.number == number &&
        other.title == title &&
        other.state == state;
  }

  @override
  int get hashCode => number.hashCode ^ title.hashCode ^ state.hashCode;

  @override
  String toString() => 'Issue(#$number: $title, state: $state)';
}

/// GitHub Label model
@JsonSerializable()
class Label {
  final int? id;
  final String name;
  final String color;
  final String? description;
  final String? url;

  Label({
    this.id,
    required this.name,
    required this.color,
    this.description,
    this.url,
  });

  factory Label.fromJson(Map<String, dynamic> json) => _$LabelFromJson(json);
  Map<String, dynamic> toJson() => _$LabelToJson(this);

  /// Get color as Flutter Color (from hex string)
  // Note: Import dart:ui or flutter/material to use Color
  // Color get colorAsFlutter => Color(int.parse(color, radix: 16) + 0xFF000000);

  @override
  String toString() => 'Label($name)';
}

/// GitHub Milestone model
@JsonSerializable()
class Milestone {
  final int number;
  final String title;
  final String? description;
  final String state; // 'open' or 'closed'
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;
  @JsonKey(name: 'closed_at')
  final DateTime? closedAt;
  @JsonKey(name: 'due_on')
  final DateTime? dueOn;
  @JsonKey(name: 'closed_issues')
  final int? closedIssues;
  @JsonKey(name: 'open_issues')
  final int? openIssues;

  Milestone({
    required this.number,
    required this.title,
    this.description,
    required this.state,
    required this.createdAt,
    this.updatedAt,
    this.closedAt,
    this.dueOn,
    this.closedIssues,
    this.openIssues,
  });

  factory Milestone.fromJson(Map<String, dynamic> json) =>
      _$MilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$MilestoneToJson(this);

  bool get isOpen => state == 'open';
  bool get isClosed => state == 'closed';

  @override
  String toString() => 'Milestone(#$number: $title)';
}

/// GitHub User model
@JsonSerializable()
class User {
  final String login;
  final int? id;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'html_url')
  final String? htmlUrl;
  final String? name;
  final String? email;
  @JsonKey(name: 'company')
  final String? company;
  @JsonKey(name: 'blog')
  final String? blog;
  final String? location;
  final String? bio;

  User({
    required this.login,
    this.id,
    this.avatarUrl,
    this.htmlUrl,
    this.name,
    this.email,
    this.company,
    this.blog,
    this.location,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// Get display name (name or login)
  String get displayName => name ?? login;

  @override
  String toString() => 'User($login)';
}

/// Simple repository configuration model (legacy - for backward compatibility)
class Repository {
  final String owner;
  final String name;

  Repository({required this.owner, required this.name});

  /// Get full repository name in format 'owner/name'
  String get fullName => '$owner/$name';
}
