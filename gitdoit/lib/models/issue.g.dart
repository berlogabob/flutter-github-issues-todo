// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Issue _$IssueFromJson(Map<String, dynamic> json) => Issue(
  number: (json['number'] as num).toInt(),
  title: json['title'] as String,
  body: json['body'] as String?,
  state: json['state'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  labels:
      (json['labels'] as List<dynamic>?)
          ?.map((e) => Label.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  milestone: json['milestone'] == null
      ? null
      : Milestone.fromJson(json['milestone'] as Map<String, dynamic>),
  assignee: json['assignee'] == null
      ? null
      : User.fromJson(json['assignee'] as Map<String, dynamic>),
  assignees:
      (json['assignees'] as List<dynamic>?)
          ?.map((e) => User.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  htmlUrl: json['html_url'] as String?,
  repositoryUrl: json['repository_url'] as String?,
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$IssueToJson(Issue instance) => <String, dynamic>{
  'number': instance.number,
  'title': instance.title,
  'body': instance.body,
  'state': instance.state,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'labels': instance.labels,
  'milestone': instance.milestone,
  'assignee': instance.assignee,
  'assignees': instance.assignees,
  'html_url': instance.htmlUrl,
  'repository_url': instance.repositoryUrl,
  'user': instance.user,
};

Label _$LabelFromJson(Map<String, dynamic> json) => Label(
  id: (json['id'] as num?)?.toInt(),
  name: json['name'] as String,
  color: json['color'] as String,
  description: json['description'] as String?,
  url: json['url'] as String?,
);

Map<String, dynamic> _$LabelToJson(Label instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'color': instance.color,
  'description': instance.description,
  'url': instance.url,
};

Milestone _$MilestoneFromJson(Map<String, dynamic> json) => Milestone(
  number: (json['number'] as num).toInt(),
  title: json['title'] as String,
  description: json['description'] as String?,
  state: json['state'] as String,
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: json['updated_at'] == null
      ? null
      : DateTime.parse(json['updated_at'] as String),
  closedAt: json['closed_at'] == null
      ? null
      : DateTime.parse(json['closed_at'] as String),
  dueOn: json['due_on'] == null
      ? null
      : DateTime.parse(json['due_on'] as String),
  closedIssues: (json['closed_issues'] as num?)?.toInt(),
  openIssues: (json['open_issues'] as num?)?.toInt(),
);

Map<String, dynamic> _$MilestoneToJson(Milestone instance) => <String, dynamic>{
  'number': instance.number,
  'title': instance.title,
  'description': instance.description,
  'state': instance.state,
  'created_at': instance.createdAt.toIso8601String(),
  'updated_at': instance.updatedAt?.toIso8601String(),
  'closed_at': instance.closedAt?.toIso8601String(),
  'due_on': instance.dueOn?.toIso8601String(),
  'closed_issues': instance.closedIssues,
  'open_issues': instance.openIssues,
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
