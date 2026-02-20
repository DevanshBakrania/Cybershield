import 'dart:io';
import 'dart:ui';
import 'dart:math';

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
import '../../services/intruder_capture_service.dart';

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
          title: const Text(
              "MASTER VAULT",
              style: TextStyle(letterSpacing: 2, fontWeight: FontWeight.bold, color: Color(0xFFCCFF00))
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            // ✨ FIXED: Wrapped in an IconButton so it actually clicks!
            IconButton(
              padding: const EdgeInsets.only(right: 16.0),
              icon: const Icon(Icons.lock_outline, color: Color(0xFFCCFF00)),
              onPressed: () {
                // Instantly kicks the user out of the vault back to the Dashboard
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Vault securely locked.", style: TextStyle(color: Colors.black)),
                      backgroundColor: Color(0xFFCCFF00),
                      duration: Duration(seconds: 1),
                    )
                );
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                padding: const EdgeInsets.all(24),
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                children: [
                  // ✨ UPDATED: Icons and colors mapped to match your screenshot reference
                  _tile("PASSWORDS", Icons.password, Colors.blueAccent, "Password"),
                  _tile("SECURE NOTES", Icons.insert_drive_file, Colors.amberAccent, "Note"),
                  _tile("FILES", Icons.folder, Colors.purpleAccent, "File"),
                  _tile("INTRUDER LOGS", Icons.warning_amber_rounded, Colors.pinkAccent, "Evidence"),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return _buildItemList(_selectedCategory!);
  }

  // ✨ UPDATED: Flat, minimalist design matching your screenshot
  Widget _tile(String title, IconData icon, Color color, String category) {
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      onLongPress: () async {
        // ✨ DIAGNOSTIC CAMERA TEST: Expanded with permissions and explicit error catching
        if (category == "Evidence") {
          try {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Checking camera permissions...")));
            var status = await Permission.camera.request();

            if (!status.isGranted) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("FAILED: Camera permission denied!")));
              return;
            }

            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test: Snapping Intruder Photo...")));
            await IntruderTrapService.init(widget.user.username);
            await IntruderTrapService.capture(widget.user.username);
            setState(() {});
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Test Complete! Open Intruder Logs.")));
          } catch (e) {
            // This will print the exact reason the camera is failing directly to your screen
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("CAMERA CRASH: $e"), backgroundColor: Colors.red));
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03), // Very subtle flat background
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0), // Thin clean border
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: color),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                    fontSize: 12)),
            const SizedBox(height: 8),
            Text(
              "${_vaultBox.values.where((e) => e.category == category && e.title.isNotEmpty).length} Items",
              style: const TextStyle(color: Colors.white54, fontSize: 12),
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
      if (e.title.isEmpty) return false;
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Decrypt & search...",
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                prefixIcon: const Icon(Icons.search, color: CyberTheme.neonGreen),
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
          : FloatingActionButton.extended(
        backgroundColor: CyberTheme.neonGreen,
        icon: const Icon(Icons.enhanced_encryption, color: Colors.black),
        label: const Text("ENCRYPT NEW", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        onPressed: () => _addItem(category),
      ),
      body: items.isEmpty
          ? Center(
        child: category == "Evidence"
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, size: 100, color: CyberTheme.neonGreen.withValues(alpha: 0.4)),
            const SizedBox(height: 24),
            const Text("SYSTEM SECURE", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2)),
            const SizedBox(height: 8),
            const Text("0 BREACHES DETECTED", style: TextStyle(color: Colors.white54, letterSpacing: 1)),
          ],
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.folder_off_outlined, size: 80, color: Colors.white24),
            const SizedBox(height: 16),
            const Text("NO ENCRYPTED DATA", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
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
            color: item.isPinned ? CyberTheme.neonGreen : Colors.white12,
            width: item.isPinned ? 2 : 1
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: _buildLeadingIcon(item, category),
        title: Text(
          category == "Note" ? "[${item.subCategory}] ${item.title}" : item.title,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: _buildSubtitle(item, category),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category != "Evidence")
              IconButton(
                icon: Icon(Icons.push_pin, color: item.isPinned ? CyberTheme.neonGreen : Colors.grey),
                onPressed: () {
                  item.isPinned = !item.isPinned;
                  item.save();
                  setState(() {});
                },
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
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
            _editItem(item, category);
          }
        },
      ),
    );
  }

  Widget _buildLeadingIcon(VaultItem item, String category) {
    if (category == "Evidence") {
      try {
        final path = _encryption.decrypt(item.content).trim();
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(path),
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: CyberTheme.dangerRed),
          ),
        );
      } catch (e) {
        return const Icon(Icons.warning, color: CyberTheme.dangerRed);
      }
    }
    return Icon(
      item.isPinned ? Icons.push_pin : Icons.lock_outline,
      color: item.isPinned ? CyberTheme.neonGreen : Colors.grey,
    );
  }

  Widget? _buildSubtitle(VaultItem item, String category) {
    if (category == "Password") {
      return const Padding(
        padding: EdgeInsets.only(top: 4.0),
        child: Text("••••••••••••", style: TextStyle(color: Colors.white54, letterSpacing: 2, fontSize: 16)),
      );
    } else if (category == "Evidence") {
      final dateStr = item.createdAt.toString().split('.')[0];
      return Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Text("BREACH: $dateStr", style: const TextStyle(color: CyberTheme.dangerRed, fontSize: 11, fontWeight: FontWeight.bold)),
      );
    }
    return null;
  }

  // ───────────────────────── ACTIONS ─────────────────────────

  String _generateSecurePassword() {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*()_+=-{}[]|:;<>,.?/';
    final rnd = Random();
    return String.fromCharCodes(Iterable.generate(16, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  void _editItem(VaultItem item, String category) {
    final title = TextEditingController(text: item.title);
    final sub = TextEditingController(text: item.subCategory);

    final content = TextEditingController(text: _encryption.decrypt(item.content));
    bool obscureSecret = category == "Password";

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: CyberTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CyberTheme.neonGreen.withValues(alpha: 0.5), width: 1.5),
              ),
              title: Row(
                children: [
                  Icon(Icons.edit, color: CyberTheme.neonGreen),
                  const SizedBox(width: 8),
                  Text("EDIT $category".toUpperCase(), style: const TextStyle(color: CyberTheme.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category == "Note")
                      _buildDialogField("Category", sub, false, null),
                    _buildDialogField("Title (e.g. Gmail)", title, false, null),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: content,
                        obscureText: obscureSecret,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Secret Payload",
                          labelStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonGreen)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureSecret ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setDialogState(() => obscureSecret = !obscureSecret),
                          ),
                        ),
                      ),
                    ),

                    if (category == "Password")
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CyberTheme.neonGreen,
                          side: BorderSide(color: CyberTheme.neonGreen.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Generate New Password", style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setDialogState(() {
                            content.text = _generateSecurePassword();
                            obscureSecret = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (title.text.trim().isEmpty || content.text.trim().isEmpty) return;

                    item.title = title.text.trim();
                    item.subCategory = sub.text.trim();
                    item.content = _encryption.encrypt(content.text);
                    item.save();

                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
      ),
    );
  }

  void _addItem(String category) {
    if (category == "File") {
      _pickAndSaveFile();
      return;
    }

    final title = TextEditingController();
    final sub = TextEditingController(text: "General");
    final content = TextEditingController();
    bool obscureSecret = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: CyberTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: CyberTheme.neonGreen.withValues(alpha: 0.5), width: 1.5),
              ),
              title: Row(
                children: [
                  Icon(category == "Password" ? Icons.vpn_key : Icons.text_snippet, color: CyberTheme.neonGreen),
                  const SizedBox(width: 8),
                  Text("SECURE $category".toUpperCase(), style: const TextStyle(color: CyberTheme.neonGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (category == "Note")
                      _buildDialogField("Category", sub, false, null),
                    _buildDialogField("Title (e.g. Gmail)", title, false, null),

                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: TextField(
                        controller: content,
                        obscureText: obscureSecret,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Secret Payload",
                          labelStyle: const TextStyle(color: Colors.white54),
                          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonGreen)),
                          suffixIcon: IconButton(
                            icon: Icon(obscureSecret ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                            onPressed: () => setDialogState(() => obscureSecret = !obscureSecret),
                          ),
                        ),
                      ),
                    ),

                    if (category == "Password")
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CyberTheme.neonGreen,
                          side: BorderSide(color: CyberTheme.neonGreen.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text("Generate Secure Password", style: TextStyle(fontSize: 12)),
                        onPressed: () {
                          setDialogState(() {
                            content.text = _generateSecurePassword();
                            obscureSecret = false;
                          });
                        },
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CyberTheme.neonGreen,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    if (title.text.trim().isEmpty || content.text.trim().isEmpty) return;

                    _vaultBox.add(
                      VaultItem(
                        username: widget.user.username,
                        title: title.text.trim(),
                        subCategory: sub.text.trim(),
                        content: _encryption.encrypt(content.text),
                        category: category,
                        createdAt: DateTime.now(),
                      ),
                    );
                    Navigator.pop(context);
                    setState(() {});
                  },
                  child: const Text("ENCRYPT & SAVE", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          }
      ),
    );
  }

  Widget _buildDialogField(String label, TextEditingController controller, bool obscure, Widget? suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: CyberTheme.neonGreen)),
          suffixIcon: suffix,
        ),
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
      final decryptedPath = _encryption.decrypt(encPath).trim();
      final imageFile = File(decryptedPath);

      showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: CyberTheme.neonGreen.withValues(alpha: 0.5), width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.lock_open, color: CyberTheme.neonGreen),
            SizedBox(width: 8),
            Text("DECRYPTED PAYLOAD", style: TextStyle(color: CyberTheme.neonGreen, fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: SelectableText(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE", style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}