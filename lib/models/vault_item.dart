import 'package:hive/hive.dart';

part 'vault_item.g.dart'; // ⚠️ This line must match the file name!

@HiveType(typeId: 1) // Unique ID for this class
class VaultItem extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String content; // Encrypted string

  @HiveField(2)
  String category; // "Password", "Note", "File"

  @HiveField(3)
  DateTime createdAt;

  @HiveField(4)
  bool isPinned;

  @HiveField(5)
  String subCategory; // e.g. "Social", "Work"

  VaultItem({
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isPinned = false,
    this.subCategory = 'General',
  });
}