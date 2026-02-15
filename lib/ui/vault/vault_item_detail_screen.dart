import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_file/open_file.dart';

import '../../utils/secure_screen.dart';
import '../../models/user_model.dart';
import '../../models/vault_item.dart';
import '../../security/vault_service.dart';
import '../../core/theme.dart';
import 'vault_unlock_screen.dart';

final VaultService _vault = VaultService();

class VaultItemDetailScreen extends StatefulWidget {
  final UserModel user;
  final VaultItem item;

  const VaultItemDetailScreen({
    super.key,
    required this.user,
    required this.item,
  });

  @override
  State<VaultItemDetailScreen> createState() =>
      _VaultItemDetailScreenState();
}

class _VaultItemDetailScreenState extends State<VaultItemDetailScreen> {
  static const Color neon = Color(0xFF39FF14);

  String? decrypted;
  late bool isTrap;
  bool _ready = false;

  // ───────────────── INIT ─────────────────

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    // 🔐 CRITICAL FIX
    await _vault.init(widget.user.username);

    isTrap = widget.item.isTrap;

    if (isTrap) {
      await Future.delayed(const Duration(milliseconds: 300));
      SystemNavigator.pop();
      return;
    }

    decrypted = _vault.decrypt(widget.item.content);
    if (mounted) {
      setState(() => _ready = true);
    }
  }

  @override
  void dispose() {
    SecureScreen.disable();
    super.dispose();
  }

  // ───────────────── MANUAL LOCK ─────────────────

  void _manualLock() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => VaultUnlockScreen(user: widget.user),
      ),
      (_) => false,
    );
  }

  // ───────────────── DELETE ─────────────────

  Future<void> _delete() async {
    await widget.item.delete();
    if (!mounted) return;
    Navigator.pop(context);
  }

  // ───────────────── EDIT ─────────────────

  void _edit() {
    final ctrl = TextEditingController(text: decrypted ?? "");

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        title: const Text(
          "Edit Item",
          style: TextStyle(color: neon),
        ),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: neon,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              widget.item.content = _vault.encrypt(ctrl.text);
              widget.item.save();
              Navigator.pop(context);
              setState(() => decrypted = ctrl.text);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // ───────────────── OPEN FILE ─────────────────

  Future<void> _openFile() async {
    if (decrypted == null) return;
    final file = File(decrypted!);
    if (await file.exists()) {
      await OpenFile.open(file.path);
    }
  }

  // ───────────────── UI ─────────────────

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: CyberTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: neon),
        ),
      );
    }

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: Text(widget.item.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_outline, color: neon),
            onPressed: _manualLock,
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: _edit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _delete,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _typeChip(widget.item.category),
            const SizedBox(height: 16),
           Expanded(
  child: (widget.item.category == "File" ||
          widget.item.category == "Evidence")
      ? _fileView()
      : SelectableText(
          decrypted!,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
),

          ],
        ),
      ),
    );
  }

  // ───────────────── HELPERS ─────────────────

  Widget _typeChip(String category) {
    Color c;
    switch (category) {
      case "Password":
        c = Colors.green;
        break;
      case "File":
        c = Colors.purple;
        break;
      case "Evidence":
        c = Colors.orange;
        break;
      default:
        c = Colors.blue;
    }

    return Chip(
      label: Text(category),
      backgroundColor: c.withOpacity(0.2),
      labelStyle: TextStyle(color: c),
    );
  }

  Widget _fileView() {
    return Center(
      child: ElevatedButton.icon(
        icon: const Icon(Icons.open_in_new),
        label: const Text("Open File"),
        style: ElevatedButton.styleFrom(
          backgroundColor: neon,
          foregroundColor: Colors.black,
        ),
        onPressed: _openFile,
      ),
    );
  }
}
