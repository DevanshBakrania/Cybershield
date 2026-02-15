import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../models/user_model.dart';
import '../../models/vault_item.dart';
import '../../security/password_hash.dart';
import '../../storage/hive_boxes.dart';
import '../../security/vault_service.dart';
import '../../utils/secure_screen.dart';
import '../../core/theme.dart';
import 'vault_unlock_screen.dart';

final VaultService _vault = VaultService();

enum VaultItemType { note, password, file }

class VaultAddItemScreen extends StatefulWidget {
  final UserModel user;
  const VaultAddItemScreen({super.key, required this.user});

  @override
  State<VaultAddItemScreen> createState() => _VaultAddItemScreenState();
}

class _VaultAddItemScreenState extends State<VaultAddItemScreen> {
  static const Color neon = Color(0xFF39FF14); // ✅ NEW COLOR

  VaultItemType _type = VaultItemType.note;

  final titleCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final contentCtrl = TextEditingController();

  bool isTrap = false;
  bool hashPassword = true;
  bool _saving = false;

  File? pickedFile;

  // ───────────────── SCREEN PROTECTION ─────────────────

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _vault.init(widget.user.username);
  }

  @override
  void dispose() {
    SecureScreen.disable();
    titleCtrl.dispose();
    categoryCtrl.dispose();
    contentCtrl.dispose();
    super.dispose();
  }

  // ───────────────── SAVE ─────────────────

Future<void> _save() async {
  if (_saving) return;
  if (titleCtrl.text.trim().isEmpty) return;

  setState(() => _saving = true);

  try {
    final subCategory = categoryCtrl.text.trim().isEmpty
        ? "General"
        : categoryCtrl.text.trim();

    String encryptedContent;

    if (_type == VaultItemType.file) {
      if (pickedFile == null) throw Exception("No file selected");

      final dir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${dir.path}/vault_files');

      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      final newPath =
          '${vaultDir.path}/${pickedFile!.path.split('/').last}';
      await pickedFile!.copy(newPath);

      encryptedContent = _vault.encrypt(newPath);
    } else {
      encryptedContent = _vault.encrypt(contentCtrl.text);
    }

    await HiveBoxes.vault.add(
      VaultItem(
        username: widget.user.username,
        title: titleCtrl.text.trim(),
        content: encryptedContent,
        category: _type == VaultItemType.note
            ? "Note"
            : _type == VaultItemType.password
                ? "Password"
                : "File",
        subCategory: subCategory,
        createdAt: DateTime.now(),
        isTrap: isTrap,
      ),
    );

    if (mounted) Navigator.pop(context);
  } catch (e, s) {
    debugPrint("❌ SAVE FAILED: $e");
    debugPrint("$s");

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Save failed")),
    );
  } finally {
    if (mounted) setState(() => _saving = false);
  }
}

  // ───────────────── FILE PICK ─────────────────

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.single.path == null) return;

    setState(() {
      pickedFile = File(result.files.single.path!);
      titleCtrl.text = result.files.single.name;
    });
  }

  // ───────────────── UI HELPERS ─────────────────

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }

  // ───────────────── BUILD ─────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: const Text("Add Vault Item"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: neon),
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => VaultUnlockScreen(user: widget.user),
                ),
                (_) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // TYPE
          _card(
            Wrap(
              spacing: 12,
              children: VaultItemType.values.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(
                    t.name.toUpperCase(),
                    style: TextStyle(
                        color: selected ? Colors.black : Colors.white),
                  ),
                  selected: selected,
                  selectedColor: neon,
                  backgroundColor: CyberTheme.surface,
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
          ),

          // TITLE + CATEGORY
          _card(
            Column(
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                      labelText: "Category (optional)"),
                ),
              ],
            ),
          ),

          // CONTENT
          if (_type != VaultItemType.file)
            _card(
              Column(
                children: [
                  TextField(
                    controller: contentCtrl,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                        labelText: "Secret Content"),
                  ),
                  if (_type == VaultItemType.password)
                    SwitchListTile(
                      value: hashPassword,
                      onChanged: (v) =>
                          setState(() => hashPassword = v),
                      activeColor: neon,
                      title: const Text(
                        "Hash password",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),

          // FILE
          if (_type == VaultItemType.file)
            _card(
              Column(
                children: [
                  ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text("Pick File"),
                    onPressed: _pickFile,
                  ),
                  if (pickedFile != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        pickedFile!.path.split('/').last,
                        style:
                            const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),

          // TRAP
          _card(
            SwitchListTile(
              value: isTrap,
              onChanged: (v) => setState(() => isTrap = v),
              activeColor: Colors.red,
              title: const Text(
                "Trap / Decoy Item",
                style: TextStyle(color: Colors.red),
              ),
              subtitle: const Text(
                "Opening this item will immediately close the app",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          ),

          // SAVE
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: neon,
                foregroundColor: Colors.black,
              ),
              child: _saving
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text(
                      "Save Item",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
