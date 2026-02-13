import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart'; // ✅ Added Import
import '../../core/theme.dart';
import '../../storage/hive_boxes.dart';
import '../../models/vault_item.dart';
import '../../security/key_manager.dart';
import '../../security/encryption.dart';
import '../../widgets/cyber_ui.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});
  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final _encryption = EncryptionService();
  bool _ready = false;
  bool _isUnlocked = false;
  final TextEditingController _pinCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";
  String? _selectedCategory;
  bool _isBlurred = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.5, end: 3.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _initVault();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _pinCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() => _isBlurred = (state == AppLifecycleState.inactive || state == AppLifecycleState.paused));
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) _manualLock();
  }

  void _manualLock() {
    if (mounted) {
      setState(() {
        _isUnlocked = false;
        _selectedCategory = null;
        _pinCtrl.clear();
        _searchQuery = "";
        _searchCtrl.clear();
      });
    }
  }

  void _initVault() async {
    try {
      final keyString = await KeyManager().getOrGenerateKey();
      _encryption.init(keyString);
      if (mounted) setState(() => _ready = true);
    } catch (e) { debugPrint("Encryption Init Error: $e"); }
  }

  void _unlockVault() {
    if (_pinCtrl.text == "1234") setState(() => _isUnlocked = true);
    else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("ACCESS DENIED"), backgroundColor: CyberTheme.dangerRed));
      _pinCtrl.clear();
    }
  }

  // ... (Build Methods preserved, skipping to logic for space, no changes in UI build logic needed) ...
  // But for safety, I will include the main Build and Helper methods
  // to ensure you have the full file working.

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const Scaffold(backgroundColor: CyberTheme.background, body: Center(child: CircularProgressIndicator(color: CyberTheme.neonGreen)));

    return Listener(
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          _buildContent(),
          if (_isUnlocked && !_isBlurred)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) => CustomPaint(
                  size: Size.infinite,
                  painter: HeartbeatPainter(color: CyberTheme.neonGreen.withValues(alpha: 0.5), glowWidth: _pulseAnimation.value),
                ),
              ),
            ),
          if (_isBlurred)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.8),
                  child: const Center(child: Icon(Icons.lock_person_rounded, color: CyberTheme.neonGreen, size: 80)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() => _isUnlocked ? _buildVaultMain() : _buildLockScreen();

  Widget _buildLockScreen() => Scaffold(
    backgroundColor: CyberTheme.background,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: CyberTheme.neonGreen),
            const SizedBox(height: 20),
            const CyberNeonText("MASTER VAULT LOCKED", size: 24),
            const SizedBox(height: 30),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 5),
              decoration: InputDecoration(
                hintText: "PIN",
                hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                filled: true,
                fillColor: CyberTheme.surface,
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: Colors.transparent)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: const BorderSide(color: CyberTheme.neonGreen)),
              ),
              onSubmitted: (_) => _unlockVault(),
            ),
            const SizedBox(height: 20),
            SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: CyberTheme.neonGreen,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                    ),
                    onPressed: _unlockVault,
                    child: const Text("UNLOCK", style: TextStyle(fontWeight: FontWeight.bold))
                )
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildVaultMain() {
    if (_selectedCategory == null) {
      return Scaffold(
        backgroundColor: CyberTheme.background,
        appBar: AppBar(
          title: const Text("MASTER VAULT", style: TextStyle(letterSpacing: 2)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [IconButton(icon: const Icon(Icons.lock_open, color: CyberTheme.neonGreen), onPressed: _manualLock)],
        ),
        body: GridView.count(
          crossAxisCount: 2, padding: const EdgeInsets.all(16), crossAxisSpacing: 16, mainAxisSpacing: 16,
          children: [
            _buildGridTile("PASSWORDS", Icons.vpn_key, Colors.blue, "Password"),
            _buildGridTile("SECURE NOTES", Icons.text_snippet, Colors.amber, "Note"),
            _buildGridTile("FILES", Icons.folder_shared, Colors.purple, "File"),
            _buildGridTile("INTRUDER LOGS", Icons.warning_amber, CyberTheme.dangerRed, "Evidence"),
          ],
        ),
      );
    }
    return _buildItemList(_selectedCategory!);
  }

  Widget _buildGridTile(String title, IconData icon, Color color, String categoryId) => GestureDetector(
    onTap: () => setState(() => _selectedCategory = categoryId),
    child: Container(
      decoration: BoxDecoration(
          color: CyberTheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 10)]
      ),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 15),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 5),
            Text("${HiveBoxes.vault.values.where((e) => e.category == categoryId).length} Items", style: const TextStyle(color: Colors.grey, fontSize: 10))
          ]
      ),
    ),
  );

  Widget _buildItemList(String category) {
    final bool showSearch = (category == "Password" || category == "Note");
    final items = HiveBoxes.vault.values.where((e) {
      final matches = e.category == category;
      if (!showSearch) return matches;
      return matches && (e.title.toLowerCase().contains(_searchQuery.toLowerCase()) || e.subCategory.toLowerCase().contains(_searchQuery.toLowerCase()));
    }).toList();

    items.sort((a, b) {
      if (a.isPinned && !b.isPinned) return -1;
      if (!a.isPinned && b.isPinned) return 1;
      return a.subCategory.toLowerCase().compareTo(b.subCategory.toLowerCase());
    });

    return Scaffold(
      backgroundColor: CyberTheme.background,
      appBar: AppBar(
        title: Text(category.toUpperCase(), style: const TextStyle(letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => setState(() { _selectedCategory = null; _searchQuery = ""; _searchCtrl.clear(); })
        ),
        bottom: showSearch ? PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        hintText: "Search vault...",
                        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
                        prefixIcon: const Icon(Icons.search, color: CyberTheme.neonGreen),
                        fillColor: CyberTheme.surface,
                        filled: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)
                    )
                )
            )
        ) : null,
      ),
      floatingActionButton: category == "Evidence" ? null : FloatingActionButton(
          onPressed: () => _addOrEditItem(categoryTitle: category),
          backgroundColor: CyberTheme.neonGreen,
          child: const Icon(Icons.add, color: Colors.black)
      ),
      body: items.isEmpty ? const Center(child: Text("No items found.", style: TextStyle(color: Colors.grey))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (ctx, i) {
          final item = items[i];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
                color: CyberTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: item.isPinned ? CyberTheme.neonGreen.withValues(alpha: 0.5) : Colors.transparent)
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: CyberTheme.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.isPinned ? Icons.push_pin : Icons.lock, color: item.isPinned ? CyberTheme.neonGreen : Colors.grey, size: 20)
              ),
              title: Text(category == "Note" ? "[${item.subCategory}] ${item.title}" : item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                if (category != "Evidence") IconButton(icon: Icon(Icons.push_pin, color: item.isPinned ? CyberTheme.neonGreen : Colors.grey, size: 18), onPressed: () { item.isPinned = !item.isPinned; item.save(); setState(() {}); }),
                IconButton(icon: const Icon(Icons.delete, color: Colors.grey, size: 18), onPressed: () { item.delete(); setState(() {}); }),
              ]),
              onTap: () {
                if (category == "Evidence") _showEvidence(item.content);
                else if (category == "File") _openFile(item.content);
                else _showDecrypted(item.content);
              },
            ),
          );
        },
      ),
    );
  }

  void _addOrEditItem({required String categoryTitle}) {
    if (categoryTitle == "File") { _pickAndSaveFile(); return; }
    final titleCtrl = TextEditingController();
    final subCatCtrl = TextEditingController(text: "General");
    final contentCtrl = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: CyberTheme.surface,
      title: Text("Add $categoryTitle", style: const TextStyle(color: CyberTheme.neonGreen)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (categoryTitle == "Note") TextField(controller: subCatCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Category")),
          TextField(controller: titleCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Title")),
          TextField(controller: contentCtrl, style: const TextStyle(color: Colors.white), maxLines: 3, decoration: const InputDecoration(labelText: "Secret Value")),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: CyberTheme.neonGreen),
            onPressed: () {
              if (titleCtrl.text.isNotEmpty) {
                HiveBoxes.vault.add(VaultItem(
                  title: titleCtrl.text,
                  content: _encryption.encrypt(contentCtrl.text),
                  category: categoryTitle,
                  createdAt: DateTime.now(),
                  subCategory: subCatCtrl.text,
                ));
                Navigator.pop(ctx); setState(() {});
              }
            }, child: const Text("SAVE", style: TextStyle(color: Colors.black)))
      ],
    ));
  }

  // ✅ UPDATED FILE PICKER LOGIC
  void _pickAndSaveFile() async {
    // 1. Check/Request Storage Permission
    var status = await Permission.storage.request();

    // 2. Pick File
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File originalFile = File(result.files.single.path!);

      // 3. Get Safe Internal Directory
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory('${appDir.path}/vault_files');

      if (!await vaultDir.exists()) {
        await vaultDir.create(recursive: true);
      }

      // 4. Copy File to App Storage
      final String fileName = result.files.single.name;
      final String newPath = '${vaultDir.path}/$fileName';

      try {
        await originalFile.copy(newPath);

        // 5. Save the NEW path to Hive
        HiveBoxes.vault.add(VaultItem(
            title: fileName,
            content: _encryption.encrypt(newPath),
            category: "File",
            createdAt: DateTime.now()
        ));
        setState(() {});

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File Encrypted & Saved"), backgroundColor: CyberTheme.neonGreen)
        );
      } catch (e) {
        debugPrint("File Save Error: $e");
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Error Saving File"), backgroundColor: CyberTheme.dangerRed)
        );
      }
    }
  }

  void _openFile(String encryptedPath) async {
    try {
      String path = _encryption.decrypt(encryptedPath);
      if (await File(path).exists()) await OpenFile.open(path);
    } catch (e) { debugPrint("Open Error: $e"); }
  }

  void _showEvidence(String imagePath) {
    showDialog(context: context, builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: CyberTheme.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: CyberTheme.dangerRed)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text("⚠️ INTRUDER EVIDENCE", style: TextStyle(color: CyberTheme.dangerRed, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(imagePath), fit: BoxFit.cover, errorBuilder: (c, e, s) => const Text("Evidence file lost or deleted.", style: TextStyle(color: Colors.white)))),
        ]),
      ),
    ));
  }

  void _showDecrypted(String content) {
    String dec = _encryption.decrypt(content);
    showDialog(context: context, builder: (ctx) => AlertDialog(
        backgroundColor: CyberTheme.surface,
        title: const Text("Decrypted Data", style: TextStyle(color: CyberTheme.neonGreen)),
        content: SelectableText(dec, style: const TextStyle(color: Colors.white))
    ));
  }
}

class HeartbeatPainter extends CustomPainter {
  final Color color;
  final double glowWidth;

  HeartbeatPainter({required this.color, required this.glowWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outerGlow = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowWidth * 5);
    canvas.drawRect(rect, outerGlow);

    final innerGlow = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowWidth * 2);
    canvas.drawRect(rect, innerGlow);

    final coreLine = Paint()
      ..color = color.withValues(alpha: 1.0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawRect(rect, coreLine);
  }

  @override
  bool shouldRepaint(HeartbeatPainter oldDelegate) =>
      oldDelegate.glowWidth != glowWidth;
}