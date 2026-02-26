// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'issue_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IssueItemAdapter extends TypeAdapter<IssueItem> {
  @override
  final int typeId = 2;

  @override
  IssueItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IssueItem(
      id: fields[0] as String,
      title: fields[1] as String,
      number: fields[20] as int?,
      bodyMarkdown: fields[21] as String?,
      projectColumnName: fields[22] as String?,
      projectItemNodeId: fields[23] as String?,
      status: fields[2] as ItemStatus?,
      updatedAt: fields[3] as DateTime?,
      assigneeLogin: fields[4] as String?,
      labels: (fields[5] as List?)?.cast<String>(),
      children: (fields[6] as List?)?.cast<Item>(),
      isExpanded: fields[7] as bool,
      isLocalOnly: fields[8] as bool,
      localUpdatedAt: fields[9] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, IssueItem obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.status)
      ..writeByte(3)
      ..write(obj.updatedAt)
      ..writeByte(4)
      ..write(obj.assigneeLogin)
      ..writeByte(5)
      ..write(obj.labels)
      ..writeByte(6)
      ..write(obj.children)
      ..writeByte(7)
      ..write(obj.isExpanded)
      ..writeByte(8)
      ..write(obj.isLocalOnly)
      ..writeByte(9)
      ..write(obj.localUpdatedAt)
      ..writeByte(20)
      ..write(obj.number)
      ..writeByte(21)
      ..write(obj.bodyMarkdown)
      ..writeByte(22)
      ..write(obj.projectColumnName)
      ..writeByte(23)
      ..write(obj.projectItemNodeId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IssueItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
