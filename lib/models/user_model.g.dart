// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 2;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      fullName: fields[0] as String,
      username: fields[1] as String,
      avatarPath: fields[2] as String,
      enabledAuthMethods: (fields[3] as List).cast<String>(),
      pinHash: fields[4] as String,
      passwordHash: fields[5] as String,
      patternHash: fields[6] as String,
      biometricEnabled: fields[7] as bool,
      vaultSetupComplete: fields[8] as bool,
      vaultPinHash: fields[9] as String,
      vaultPatternHash: fields[13] as String,
      vaultPasswordHash: fields[14] as String,
      vaultBiometricEnabled: fields[10] as bool,
      vaultAuthMethods: (fields[12] as List).cast<String>(),
      createdAt: fields[11] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.fullName)
      ..writeByte(1)
      ..write(obj.username)
      ..writeByte(2)
      ..write(obj.avatarPath)
      ..writeByte(3)
      ..write(obj.enabledAuthMethods)
      ..writeByte(4)
      ..write(obj.pinHash)
      ..writeByte(5)
      ..write(obj.passwordHash)
      ..writeByte(6)
      ..write(obj.patternHash)
      ..writeByte(7)
      ..write(obj.biometricEnabled)
      ..writeByte(8)
      ..write(obj.vaultSetupComplete)
      ..writeByte(9)
      ..write(obj.vaultPinHash)
      ..writeByte(10)
      ..write(obj.vaultBiometricEnabled)
      ..writeByte(12)
      ..write(obj.vaultAuthMethods)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.vaultPatternHash)
      ..writeByte(14)
      ..write(obj.vaultPasswordHash);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
