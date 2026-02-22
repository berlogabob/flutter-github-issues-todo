import 'package:json_annotation/json_annotation.dart';

part 'github_repository.g.dart';

/// GitHub Repository model
///
/// Represents a GitHub Repository with all its properties
@JsonSerializable()
class GitHubRepository {
  final int id;
  final String nodeId;
  final String name;
  @JsonKey(name: 'full_name')
  final String fullName;
  final User? owner;
  final bool private;
  @JsonKey(name: 'html_url')
  final String htmlUrl;
  final String? description;
  final bool fork;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'pushed_at')
  final DateTime? pushedAt;
  @JsonKey(name: 'git_url')
  final String gitUrl;
  @JsonKey(name: 'ssh_url')
  final String sshUrl;
  @JsonKey(name: 'clone_url')
  final String cloneUrl;
  @JsonKey(name: 'default_branch')
  final String defaultBranch;
  @JsonKey(name: 'open_issues_count')
  final int? openIssuesCount;
  @JsonKey(name: 'stargazers_count')
  final int? stargazersCount;
  @JsonKey(name: 'watchers_count')
  final int? watchersCount;
  @JsonKey(name: 'forks_count')
  final int? forksCount;
  @JsonKey(name: 'language')
  final String? language;
  final bool archived;
  final bool disabled;
  @JsonKey(name: 'has_issues')
  final bool hasIssues;
  @JsonKey(name: 'has_projects')
  final bool hasProjects;
  @JsonKey(name: 'has_wiki')
  final bool hasWiki;
  @JsonKey(name: 'has_pages')
  final bool hasPages;
  @JsonKey(name: 'has_downloads')
  final bool hasDownloads;
  final String? homepage;

  GitHubRepository({
    required this.id,
    required this.nodeId,
    required this.name,
    required this.fullName,
    this.owner,
    required this.private,
    required this.htmlUrl,
    this.description,
    required this.fork,
    required this.createdAt,
    required this.updatedAt,
    this.pushedAt,
    required this.gitUrl,
    required this.sshUrl,
    required this.cloneUrl,
    required this.defaultBranch,
    this.openIssuesCount,
    this.stargazersCount,
    this.watchersCount,
    this.forksCount,
    this.language,
    required this.archived,
    required this.disabled,
    required this.hasIssues,
    required this.hasProjects,
    required this.hasWiki,
    required this.hasPages,
    required this.hasDownloads,
    this.homepage,
  });

  factory GitHubRepository.fromJson(Map<String, dynamic> json) =>
      _$GitHubRepositoryFromJson(json);

  Map<String, dynamic> toJson() => _$GitHubRepositoryToJson(this);

  /// Get owner login name
  String get ownerLogin => owner?.login ?? fullName.split('/').first;

  /// Check if repository is archived
  bool get isArchived => archived;

  /// Check if repository is disabled
  bool get isDisabled => disabled;

  /// Get display name (name or full name)
  String get displayName => fullName;

  /// Copy with method for immutability
  GitHubRepository copyWith({
    int? id,
    String? nodeId,
    String? name,
    String? fullName,
    User? owner,
    bool? private,
    String? htmlUrl,
    String? description,
    bool? fork,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? pushedAt,
    String? gitUrl,
    String? sshUrl,
    String? cloneUrl,
    String? defaultBranch,
    int? openIssuesCount,
    int? stargazersCount,
    int? watchersCount,
    int? forksCount,
    String? language,
    bool? archived,
    bool? disabled,
    bool? hasIssues,
    bool? hasProjects,
    bool? hasWiki,
    bool? hasPages,
    bool? hasDownloads,
    String? homepage,
  }) {
    return GitHubRepository(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      owner: owner ?? this.owner,
      private: private ?? this.private,
      htmlUrl: htmlUrl ?? this.htmlUrl,
      description: description ?? this.description,
      fork: fork ?? this.fork,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pushedAt: pushedAt ?? this.pushedAt,
      gitUrl: gitUrl ?? this.gitUrl,
      sshUrl: sshUrl ?? this.sshUrl,
      cloneUrl: cloneUrl ?? this.cloneUrl,
      defaultBranch: defaultBranch ?? this.defaultBranch,
      openIssuesCount: openIssuesCount ?? this.openIssuesCount,
      stargazersCount: stargazersCount ?? this.stargazersCount,
      watchersCount: watchersCount ?? this.watchersCount,
      forksCount: forksCount ?? this.forksCount,
      language: language ?? this.language,
      archived: archived ?? this.archived,
      disabled: disabled ?? this.disabled,
      hasIssues: hasIssues ?? this.hasIssues,
      hasProjects: hasProjects ?? this.hasProjects,
      hasWiki: hasWiki ?? this.hasWiki,
      hasPages: hasPages ?? this.hasPages,
      hasDownloads: hasDownloads ?? this.hasDownloads,
      homepage: homepage ?? this.homepage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GitHubRepository &&
        other.id == id &&
        other.name == name &&
        other.fullName == fullName;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ fullName.hashCode;

  @override
  String toString() => 'GitHubRepository($fullName)';
}

/// GitHub User model (simplified for repository owner)
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
