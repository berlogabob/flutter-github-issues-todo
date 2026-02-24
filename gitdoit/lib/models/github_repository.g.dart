// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'github_repository.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GitHubRepository _$GitHubRepositoryFromJson(Map<String, dynamic> json) =>
    GitHubRepository(
      id: (json['id'] as num).toInt(),
      nodeId: json['nodeId'] as String,
      name: json['name'] as String,
      fullName: json['full_name'] as String,
      owner: json['owner'] == null
          ? null
          : User.fromJson(json['owner'] as Map<String, dynamic>),
      private: json['private'] as bool,
      htmlUrl: json['html_url'] as String,
      description: json['description'] as String?,
      fork: json['fork'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      pushedAt: json['pushed_at'] == null
          ? null
          : DateTime.parse(json['pushed_at'] as String),
      gitUrl: json['git_url'] as String,
      sshUrl: json['ssh_url'] as String,
      cloneUrl: json['clone_url'] as String,
      defaultBranch: json['default_branch'] as String,
      openIssuesCount: (json['open_issues_count'] as num?)?.toInt(),
      stargazersCount: (json['stargazers_count'] as num?)?.toInt(),
      watchersCount: (json['watchers_count'] as num?)?.toInt(),
      forksCount: (json['forks_count'] as num?)?.toInt(),
      language: json['language'] as String?,
      archived: json['archived'] as bool,
      disabled: json['disabled'] as bool,
      hasIssues: json['has_issues'] as bool,
      hasProjects: json['has_projects'] as bool,
      hasWiki: json['has_wiki'] as bool,
      hasPages: json['has_pages'] as bool,
      hasDownloads: json['has_downloads'] as bool,
      homepage: json['homepage'] as String?,
    );

Map<String, dynamic> _$GitHubRepositoryToJson(GitHubRepository instance) =>
    <String, dynamic>{
      'id': instance.id,
      'nodeId': instance.nodeId,
      'name': instance.name,
      'full_name': instance.fullName,
      'owner': instance.owner,
      'private': instance.private,
      'html_url': instance.htmlUrl,
      'description': instance.description,
      'fork': instance.fork,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'pushed_at': instance.pushedAt?.toIso8601String(),
      'git_url': instance.gitUrl,
      'ssh_url': instance.sshUrl,
      'clone_url': instance.cloneUrl,
      'default_branch': instance.defaultBranch,
      'open_issues_count': instance.openIssuesCount,
      'stargazers_count': instance.stargazersCount,
      'watchers_count': instance.watchersCount,
      'forks_count': instance.forksCount,
      'language': instance.language,
      'archived': instance.archived,
      'disabled': instance.disabled,
      'has_issues': instance.hasIssues,
      'has_projects': instance.hasProjects,
      'has_wiki': instance.hasWiki,
      'has_pages': instance.hasPages,
      'has_downloads': instance.hasDownloads,
      'homepage': instance.homepage,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
  login: json['login'] as String,
  id: (json['id'] as num?)?.toInt(),
  avatarUrl: json['avatar_url'] as String?,
  htmlUrl: json['html_url'] as String?,
  name: json['name'] as String?,
  email: json['email'] as String?,
  company: json['company'] as String?,
  blog: json['blog'] as String?,
  location: json['location'] as String?,
  bio: json['bio'] as String?,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'login': instance.login,
  'id': instance.id,
  'avatar_url': instance.avatarUrl,
  'html_url': instance.htmlUrl,
  'name': instance.name,
  'email': instance.email,
  'company': instance.company,
  'blog': instance.blog,
  'location': instance.location,
  'bio': instance.bio,
};
