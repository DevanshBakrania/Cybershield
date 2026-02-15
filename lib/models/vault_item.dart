import 'package:hive/hive.dart';

part 'vault_item.g.dart';

@HiveType(typeId: 1)
class VaultItem extends HiveObject {
  @HiveField(0)
  String username;

  @HiveField(1)
  String title;

  @HiveField(2)
  String content;

  @HiveField(3)
  String category;

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  bool isPinned;

  @HiveField(6)
  String subCategory;

  @HiveField(7)
  bool isTrap;

  VaultItem({
    required this.username,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.isPinned = false,
    this.subCategory = 'General',
    this.isTrap = false,
  });
}
