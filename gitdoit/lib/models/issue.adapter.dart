import 'package:hive/hive.dart';
import 'issue.dart';

/// Hive TypeAdapter for Issue
///
/// Handles serialization/deserialization of Issue objects for Hive storage
class IssueAdapter extends TypeAdapter<Issue> {
  @override
  final int typeId = 0;

  @override
  Issue read(BinaryReader reader) {
    final numberOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numberOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    return Issue(
      number: fields[0] as int,
      title: fields[1] as String,
      body: fields[2] as String?,
      state: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
      closedAt: fields[6] as DateTime?,
      labels: (fields[7] as List?)?.cast<Label>() ?? const [],
      milestone: fields[8] as Milestone?,
      assignee: fields[9] as User?,
      assignees: (fields[10] as List?)?.cast<User>() ?? const [],
      htmlUrl: fields[11] as String?,
      repositoryUrl: fields[12] as String?,
      user: fields[13] as User?,
    );
  }

  @override
  void write(BinaryWriter writer, Issue obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.state)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.closedAt)
      ..writeByte(7)
      ..write(obj.labels)
      ..writeByte(8)
      ..write(obj.milestone)
      ..writeByte(9)
      ..write(obj.assignee)
      ..writeByte(10)
      ..write(obj.assignees)
      ..writeByte(11)
      ..write(obj.htmlUrl)
      ..writeByte(12)
      ..write(obj.repositoryUrl)
      ..writeByte(13)
      ..write(obj.user);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is IssueAdapter;
}

/// Hive TypeAdapter for Label
class LabelAdapter extends TypeAdapter<Label> {
  @override
  final int typeId = 1;

  @override
  Label read(BinaryReader reader) {
    final numberOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numberOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    return Label(
      id: fields[0] as int?,
      name: fields[1] as String,
      color: fields[2] as String,
      description: fields[3] as String?,
      url: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Label obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.color)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.url);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is LabelAdapter;
}

/// Hive TypeAdapter for Milestone
class MilestoneAdapter extends TypeAdapter<Milestone> {
  @override
  final int typeId = 2;

  @override
  Milestone read(BinaryReader reader) {
    final numberOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numberOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    return Milestone(
      number: fields[0] as int,
      title: fields[1] as String,
      description: fields[2] as String?,
      state: fields[3] as String,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime?,
      closedAt: fields[6] as DateTime?,
      dueOn: fields[7] as DateTime?,
      closedIssues: fields[8] as int?,
      openIssues: fields[9] as int?,
    );
  }

  @override
  void write(BinaryWriter writer, Milestone obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.number)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.state)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.closedAt)
      ..writeByte(7)
      ..write(obj.dueOn)
      ..writeByte(8)
      ..write(obj.closedIssues)
      ..writeByte(9)
      ..write(obj.openIssues);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is MilestoneAdapter;
}

/// Hive TypeAdapter for User
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 3;

  @override
  User read(BinaryReader reader) {
    final numberOfFields = reader.readByte();
    final fields = <int, dynamic>{};

    for (int i = 0; i < numberOfFields; i++) {
      final fieldId = reader.readByte();
      fields[fieldId] = reader.read();
    }

    return User(
      login: fields[0] as String,
      id: fields[1] as int?,
      avatarUrl: fields[2] as String?,
      htmlUrl: fields[3] as String?,
      name: fields[4] as String?,
      email: fields[5] as String?,
      company: fields[6] as String?,
      blog: fields[7] as String?,
      location: fields[8] as String?,
      bio: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.login)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.avatarUrl)
      ..writeByte(3)
      ..write(obj.htmlUrl)
      ..writeByte(4)
      ..write(obj.name)
      ..writeByte(5)
      ..write(obj.email)
      ..writeByte(6)
      ..write(obj.company)
      ..writeByte(7)
      ..write(obj.blog)
      ..writeByte(8)
      ..write(obj.location)
      ..writeByte(9)
      ..write(obj.bio);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserAdapter;
}
