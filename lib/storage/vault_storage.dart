import 'package:hive_flutter/hive_flutter.dart';
import '../models/vault_item.dart';
import 'hive_boxes.dart';

class VaultStorage {
  // Get reference to the vault box
  Box<VaultItem> get _box => HiveBoxes.vault;

  /// Saves an ALREADY ENCRYPTED item to the database
  Future<void> saveItem(VaultItem item) async {
    await _box.add(item);
  }

  /// Returns all encrypted items
  List<VaultItem> getAllItems() {
    final items = _box.values.toList().cast<VaultItem>();
    // Sort by creation date (newest first)
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> deleteItem(dynamic key) async {
    await _box.delete(key);
  }

  /// DANGER: Wipes the entire vault instantly
  Future<void> selfDestruct() async {
    await _box.clear();
  }
}