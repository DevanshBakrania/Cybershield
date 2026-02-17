import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hive/hive.dart';

import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../models/vault_item.dart';
import '../../security/key_manager.dart';
import '../../security/encryption.dart';
import '../../widgets/cyber_ui.dart';

class VaultScreen extends StatefulWidget {
  final UserModel user;
  const VaultScreen({super.key, required this.user});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _encryption = EncryptionService();

  late Box<VaultItem> _vaultBox;

  bool _ready = false;
  bool _isBlurred = false;

  String? _selectedCategory;
  String _searchQuery = "";

  final _searchCtrl = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ───────────────────────── INIT ─────────────────────────

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initVault();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isBlurred =
          state == AppLifecycleState.paused ||
              state == AppLifecycleState.inactive;
    });
  }

  Future<void> _initVault() async {
    try {
      final key = await KeyManager().getOrGenerateKey();
      _encryption.init(key);

      final boxName = 'vault_${widget.user.username}';
      _vaultBox = await Hive.openBox<VaultItem>(boxName);

      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 2),
      )..repeat(reverse: true);

      _pulseAnimation = Tween<double>(begin: 0.5, end: 3.0).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
      );

      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint("Vault init error: $e");
    }
  }

  // ───────────────────────── BUILD ─────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        backgroundColor: CyberTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: CyberTheme.neonGreen),
        ),
      );
    }

    return Stack(
      children: [
        _buildVaultMain(),
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) => CustomPaint(
              size: Size.infinite,
              painter: HeartbeatPainter(
                color: CyberTheme.neonGreen.withValues(alpha: 0.5),
                glowWidth: _pulseAnimation.value,
              ),
            ),
          ),
        ),
        if (_isBlurred)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                color: Colors.black.withValues(alpha: 0.85),
                child: const Center(
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: CyberTheme.neonGreen,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ───────────────────────── HOME ─────────────────────────

  Widget _buildVaultMain() {
    if (_selectedCategory == null) {
      return Scaffold(
        backgroundColor: CyberTheme.background,
        appBar: AppBar(
          title: const Text("MASTER VAULT", style: TextStyle(letterSpacing: 2)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: GridView.count(
          crossAxisCount: 2,
          padding: const EdgeInsets.all(16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _tile("PASSWORDS", Icons.vpn_key, Colors.blue, "Password"),
            _tile("SECURE NOTES", Icons.text_snippet, Colors.amber, "Note"),
            _tile("FILES", Icons.folder_shared, Colors.purple, "File"),
            _tile("INTRUDER LOGS", Icons.warning_amber,
                CyberTheme.dangerRed, "Evidence"),
          ],
        ),
      );
    }

    return _buildItemList(_selectedCategory!);
  }

  Widget _tile(String title, IconData icon, Color color, String category) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        decoration: BoxDecoration(
          color: CyberTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 12),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              "${_vaultBox.values.where((e) => e.category == category).length} Items",
              style: const TextStyle(color: Colors.grey, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── LIST ─────────────────────────

  Widget _buildItemList(String category) {
    final searchable = category == "Password" || category == "Note";

    final items = _vaultBox.values.where((e) {
      if (e.category != category) return false;
      if (!searchable) return true;
      return e.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          e.subCategory.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList()
      ..sort((a, b) {
        if (a.isPinned && !b.isPinned) return -1;
        if (!a.isPinned && b.isPinned) return 1;
        return a.subCategory.compareTo(b.subCategory);
      });

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(category.toUpperCase(), style: const TextStyle(letterSpacing: 2)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () {
            setState(() {
              _selectedCategory = null;
              _searchQuery = "";
              _searchCtrl.clear();
            });
          },
        ),
        bottom: searchable
            ? PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Search vault...",
                hintStyle:
                TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search,
                    color: CyberTheme.neonGreen),
                filled: true,
                fillColor: CyberTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        )
            : null,
      ),
      floatingActionButton: category == "Evidence"
          ? null
          : FloatingActionButton(
        backgroundColor: CyberTheme.neonGreen,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _addItem(category),
      ),
      body: items.isEmpty
          ? const Center(
        child: Text("No items found",
            style: TextStyle(color: Colors.grey)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _itemTile(items[i], category),
      ),
    );
  }

  // ───────────────────────── ITEM ─────────────────────────

  Widget _itemTile(VaultItem item, String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.isPinned
              ? CyberTheme.neonGreen.withValues(alpha: 0.5)
              : Colors.transparent,
        ),
      ),
      child: ListTile(
        leading: Icon(
          item.isPinned ? Icons.push_pin : Icons.lock,
          color: item.isPinned ? CyberTheme.neonGreen : Colors.grey,
        ),
        title: Text(
          category == "Note"
              ? "[${item.subCategory}] ${item.title}"
              : item.title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != "Evidence")
              IconButton(
                icon: Icon(Icons.push_pin,
                    color: item.isPinned
                        ? CyberTheme.neonGreen
                        : Colors.grey),
                onPressed: () {
                  item.isPinned = !item.isPinned;
                  item.save();
                  setState(() {});
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.grey),
              onPressed: () {
                item.delete();
                setState(() {});
              },
            ),
          ],
        ),
        onTap: () {
          if (category == "File") {
            _openFile(item.content);
          } else if (category == "Evidence") {
            _showEvidence(item.content);
          } else {
            _showDecrypted(item.content);
          }
        },
      ),
    );
  }

  // ───────────────────────── ACTIONS ─────────────────────────

  void _addItem(String category) {
    if (category == "File") {
      _pickAndSaveFile();
      return;
    }

    final title = TextEditingController();
    final sub = TextEditingController(text: "General");
    final content = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        title: Text("Add $category",
            style: const TextStyle(color: CyberTheme.neonGreen)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category == "Note")
              TextField(
                  controller: sub,
                  decoration: const InputDecoration(labelText: "Category")),
            TextField(
                controller: title,
                decoration: const InputDecoration(labelText: "Title")),
            TextField(
                controller: content,
                decoration: const InputDecoration(labelText: "Secret")),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              _vaultBox.add(
                VaultItem(
                  username: widget.user.username,
                  title: title.text,
                  subCategory: sub.text,
                  content: _encryption.encrypt(content.text),
                  category: category,
                  createdAt: DateTime.now(),
                ),
              );
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndSaveFile() async {
    await Permission.storage.request();
    final res = await FilePicker.platform.pickFiles();
    if (res == null || res.files.single.path == null) return;

    final src = File(res.files.single.path!);
    final dir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${dir.path}/vault_${widget.user.username}');
    if (!vaultDir.existsSync()) vaultDir.createSync(recursive: true);

    final newPath = '${vaultDir.path}/${res.files.single.name}';
    await src.copy(newPath);

    _vaultBox.add(
      VaultItem(
        username: widget.user.username,
        title: res.files.single.name,
        content: _encryption.encrypt(newPath),
        category: "File",
        createdAt: DateTime.now(),
      ),
    );

    setState(() {});
  }

  void _openFile(String enc) async {
    final path = _encryption.decrypt(enc);
    if (await File(path).exists()) OpenFile.open(path);
  }

  void _showEvidence(String encPath) {
    try {
      // Decrypt and trim any accidental invisible spaces
      final decryptedPath = _encryption.decrypt(encPath).trim();
      final imageFile = File(decryptedPath);

      debugPrint("📸 Looking for image at: ${imageFile.path}");
      debugPrint("📸 Does file exist? ${imageFile.existsSync()}");

      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: Image.file(
            imageFile,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                padding: const EdgeInsets.all(16),
                color: Colors.black87,
                child: Text(
                  "Image missing from device storage.\nPath: ${imageFile.path}",
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      debugPrint("Error showing evidence: $e");
    }
  }

  void _showDecrypted(String enc) {
    final text = _encryption.decrypt(enc);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        title: const Text("Decrypted",
            style: TextStyle(color: CyberTheme.neonGreen)),
        content:
        SelectableText(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}