import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {
  @HiveField(0)
  String fullName;

  @HiveField(1)
  String username;

  @HiveField(2)
  String pin;

  @HiveField(3)
  bool useBiometric;

  @HiveField(4)
  bool usePattern;

  @HiveField(5)
  String avatarPath;

  @HiveField(6) // <--- NEW FIELD
  String password;

  UserModel({
    required this.fullName,
    required this.username,
    required this.pin,
    this.password = "", // Default empty
    this.useBiometric = false,
    this.usePattern = false,
    this.avatarPath = "",
  });
}