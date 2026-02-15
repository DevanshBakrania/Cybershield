import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../utils/secure_screen.dart';
import '../../core/theme.dart';
import '../../models/user_model.dart';
import '../../models/vault_item.dart';
import '../../storage/hive_boxes.dart';
import '../../security/vault_service.dart';

import 'vault_add_item_screen.dart';
import 'vault_item_detail_screen.dart';
import 'vault_unlock_screen.dart';

final VaultService _vault = VaultService();

const Color neon = Color(0xFF39FF14);
const Color intruderColor = Colors.orange;

class VaultScreen extends StatefulWidget {
  final UserModel user;
  const VaultScreen({super.key, required this.user});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool _ready = false;

  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SecureScreen.enable();

    _pulseController =
        AnimationController(vsync: this, duration: const Duration(seconds: 2))
          ..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.5, end: 3.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _vault.init(widget.user.username).then((_) {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lockVault();
    }
  }

  void _lockVault() {
    _searchCtrl.clear();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => VaultUnlockScreen(user: widget.user),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _searchCtrl.dispose();
    SecureScreen.disable();
    super.dispose();
  }

  // ───────────────── UI ROOT ─────────────────

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
      floatingActionButton: FloatingActionButton(
        backgroundColor: neon,
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VaultAddItemScreen(user: widget.user),
            ),
          );
        },
      ),
      body: Stack(
        children: [
          _vaultBody(),

          IgnorePointer(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) => CustomPaint(
                size: Size.infinite,
                painter: HeartbeatPainter(
                  color: neon.withOpacity(0.35),
                  glowWidth: _pulseAnimation.value,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────── REACTIVE VAULT BODY ─────────────────

  Widget _vaultBody() {
    return ValueListenableBuilder(
      valueListenable: HiveBoxes.vault.listenable(),
      builder: (_, Box<VaultItem> box, __) {
        final userItems = box.values
            .where((e) => e.username == widget.user.username)
            .toList();

        // 🚨 Intruder logs (Evidence)
        final intruderLogs =
            userItems.where((e) => e.category == "Evidence").toList();

        // 🔐 Normal items
        final normalItems =
            userItems.where((e) => e.category != "Evidence").toList();

        final filtered = normalItems.where((item) {
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return item.title.toLowerCase().contains(q) ||
              item.subCategory.toLowerCase().contains(q);
        }).toList();

        // Group by subCategory
        final Map<String, List<VaultItem>> categories = {};
        for (final item in filtered) {
          final key = item.subCategory.trim().isEmpty
              ? "general"
              : item.subCategory.toLowerCase();
          categories.putIfAbsent(key, () => []);
          categories[key]!.add(item);
        }

        return Scaffold(
          backgroundColor: CyberTheme.background,
          appBar: AppBar(
            title: const Text("MASTER VAULT",
                style: TextStyle(letterSpacing: 2)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: neon),
              onPressed: _lockVault,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.lock_outline, color: neon),
                onPressed: _lockVault,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: "Search vault...",
                    prefixIcon: Icon(Icons.search, color: neon),
                  ),
                ),
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // NORMAL VAULT
              for (final entry in categories.entries)
                _categorySection(entry.value),

              // 🚨 INTRUDER LOGS (SEPARATE)
              if (intruderLogs.isNotEmpty) ...[
                const SizedBox(height: 24),
                _intruderSection(intruderLogs),
              ],
            ],
          ),
        );
      },
    );
  }

  // ───────────────── CATEGORY ─────────────────

  Widget _categorySection(List<VaultItem> items) {
    final title = items.first.subCategory.trim().isEmpty
        ? "GENERAL"
        : items.first.subCategory.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white12),
      ),
      child: ExpansionTile(
        collapsedIconColor: neon,
        iconColor: neon,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        children: items.map(_itemTile).toList(),
      ),
    );
  }

  // ───────────────── INTRUDER LOGS ─────────────────

  Widget _intruderSection(List<VaultItem> items) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: intruderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "INTRUDER LOGS",
            style: TextStyle(
              color: intruderColor,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map(_itemTile),
        ],
      ),
    );
  }

  // ───────────────── ITEM TILE ─────────────────

  Widget _itemTile(VaultItem item) {
    final isTrap = item.isTrap;

    Color c;
    switch (item.category) {
      case "Password":
        c = Colors.green;
        break;
      case "File":
        c = Colors.purple;
        break;
      case "Evidence":
        c = intruderColor;
        break;
      default:
        c = Colors.blue;
    }

    return ListTile(
      leading: CircleAvatar(radius: 5, backgroundColor: c),
      title:
          Text(item.title, style: const TextStyle(color: Colors.white)),
      trailing: isTrap
          ? const Icon(Icons.warning, color: Colors.red)
          : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                VaultItemDetailScreen(user: widget.user, item: item),
          ),
        );
      },
    );
  }
}

// ───────────────── HEARTBEAT ─────────────────

class HeartbeatPainter extends CustomPainter {
  final Color color;
  final double glowWidth;

  HeartbeatPainter({required this.color, required this.glowWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, glowWidth * 4);
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant HeartbeatPainter old) =>
      old.glowWidth != glowWidth;
}
