// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vault_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VaultItemAdapter extends TypeAdapter<VaultItem> {
  @override
  final int typeId = 1;

  @override
  VaultItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return VaultItem(
      username: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      category: fields[3] as String,
      createdAt: fields[4] as DateTime,
      isPinned: fields[5] as bool,
      subCategory: fields[6] as String,
      isTrap: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, VaultItem obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.category)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.isPinned)
      ..writeByte(6)
      ..write(obj.subCategory)
      ..writeByte(7)
      ..write(obj.isTrap);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
