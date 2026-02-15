import 'package:hive_flutter/hive_flutter.dart';

import '../models/vault_item.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';

class HiveBoxes {
  static late Box<UserModel> users;
  static late Box<VaultItem> vault;
  static late Box<NoteModel> dummy;
  static late Box savedNews;

  static Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(VaultItemAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(UserModelAdapter());
    }
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(NoteModelAdapter());
    }

    users = await Hive.openBox<UserModel>('users');

    // ✅ FIXED — MUST MATCH USAGE EVERYWHERE
    vault = await Hive.openBox<VaultItem>('vault');

    dummy = await Hive.openBox<NoteModel>('dummy_notes');
    savedNews = await Hive.openBox('saved_intel');
  }
}
