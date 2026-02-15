import 'package:hive_flutter/hive_flutter.dart';
import '../models/vault_item.dart';
import 'hive_boxes.dart';

class VaultStorage {
  Box<VaultItem> get _box => HiveBoxes.vault;

  /// ✅ Save item (username MUST already be inside item)
  Future<void> saveItem(VaultItem item) async {
    assert(item.username.isNotEmpty, "VaultItem.username cannot be empty");
    await _box.add(item);
  }

  /// 🔒 Get items for ONE USER only
  List<VaultItem> getUserItems(String username) {
    final items = _box.values
        .where((item) => item.username == username)
        .toList();

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  /// 🗑️ Delete single item (safe)
  Future<void> deleteItem(dynamic key) async {
    await _box.delete(key);
  }

  /// ⚠️ USER-SCOPED DESTRUCT (NOT GLOBAL)
  Future<void> selfDestructUser(String username) async {
    final keysToDelete = _box.keys.where((key) {
      final item = _box.get(key);
      return item?.username == username;
    }).toList();

    for (final key in keysToDelete) {
      await _box.delete(key);
    }
  }
}
