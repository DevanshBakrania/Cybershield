import 'package:hive_flutter/hive_flutter.dart';
import '../models/vault_item.dart';
import '../models/note_model.dart';

class HiveBoxes {
  static late Box<VaultItem> vault;
  static late Box<NoteModel> dummy;
  static late Box savedNews;

  static Future<void> init() async {
    await Hive.initFlutter();

    // 1. Register Adapters
    // Register Vault (Likely ID 0 or 1)
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(VaultItemAdapter());

    // Register Note (ID 5)
    if (!Hive.isAdapterRegistered(5)) Hive.registerAdapter(NoteModelAdapter());

    // 2. Open Boxes
    print("📦 Opening Databases...");
    try {
      vault = await Hive.openBox<VaultItem>('secure_vault');
      dummy = await Hive.openBox<NoteModel>('dummy_notes');
      savedNews = await Hive.openBox('saved_intel');
      print("✅ Databases Opened Successfully");
    } catch (e) {
      print("❌ DATABASE ERROR: $e");
    }
  }
}