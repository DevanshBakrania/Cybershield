import 'package:hive_flutter/hive_flutter.dart';

import '../models/vault_item.dart';
import '../models/note_model.dart';
import '../models/user_model.dart';

class HiveBoxes {
  static late Box<UserModel> users;
  static late Box<VaultItem> vault;
  static late Box<NoteModel> dummy;



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

    // unchanged
    vault = await Hive.openBox<VaultItem>('vault');
    dummy = await Hive.openBox<NoteModel>('dummy_notes');

    // ❌ DO NOT open saved_intel here anymore
  }

  // ✅ USER-CENTRIC SAVED INTEL (ONLY ADDITION)
  static Future<Box> openSavedNews(String username) async {
    final boxName = 'saved_intel_$username';

    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox(boxName);
    }
    return Hive.box(boxName);
  }

  static Box getSavedNews(String username) {
    return Hive.box('saved_intel_$username');
  }
}
