// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repo_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RepoItemAdapter extends TypeAdapter<RepoItem> {
  @override
  final int typeId = 1;

  @override
  RepoItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RepoItem(
      id: fields[0] as String,
      title: fields[1] as String,
      fullName: fields[10] as String,
      description: fields[11] as String?,
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
  void write(BinaryWriter writer, RepoItem obj) {
    writer
      ..writeByte(12)
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
      ..writeByte(10)
      ..write(obj.fullName)
      ..writeByte(11)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepoItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
