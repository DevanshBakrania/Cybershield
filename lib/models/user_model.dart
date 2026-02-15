import 'package:hive/hive.dart';

part 'user_model.g.dart';

@HiveType(typeId: 2)
class UserModel extends HiveObject {

  @HiveField(0)
  String fullName;

  @HiveField(1)
  String username;

  @HiveField(2)
  String avatarPath;

  // LOGIN AUTH METHODS
  @HiveField(3)
  List<String> enabledAuthMethods;

  // LOGIN SECRETS
  @HiveField(4)
  String pinHash;

  @HiveField(5)
  String passwordHash;

  @HiveField(6)
  String patternHash;

  @HiveField(7)
  bool biometricEnabled;

  // VAULT AUTH
  @HiveField(8)
  bool vaultSetupComplete;

  @HiveField(9)
  String vaultPinHash;

  @HiveField(10)
  bool vaultBiometricEnabled;

  // ✅ VAULT METHODS (SEPARATE)
  @HiveField(12)
  List<String> vaultAuthMethods;

  @HiveField(11)
  DateTime createdAt;
  @HiveField(13)
  String vaultPatternHash;
   @HiveField(14)
  String vaultPasswordHash;
  


  UserModel({
    required this.fullName,
    required this.username,
    this.avatarPath = "",

    // login
    required this.enabledAuthMethods,
    required this.pinHash,
    this.passwordHash = "",
    this.patternHash = "",
    this.biometricEnabled = false,

    // vault
    this.vaultSetupComplete = false,
    this.vaultPinHash = "",
    this.vaultPatternHash = "",
    this.vaultPasswordHash = "",
    this.vaultBiometricEnabled = false,
    this.vaultAuthMethods = const [],

    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
