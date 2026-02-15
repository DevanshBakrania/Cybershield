import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import 'vault_setup_screen.dart';
import 'vault_unlock_screen.dart';

class VaultEntryRouter extends StatefulWidget {
  final UserModel user;
  final ValueNotifier<bool> vaultLockNotifier;

  const VaultEntryRouter({
    super.key,
    required this.user,
    required this.vaultLockNotifier,
  });

  @override
  State<VaultEntryRouter> createState() => _VaultEntryRouterState();
}

class _VaultEntryRouterState extends State<VaultEntryRouter> {
  @override
  void initState() {
    super.initState();

    // 🔐 Rebuild on lock signal
    widget.vaultLockNotifier.addListener(_onLockSignal);
  }

  @override
  void dispose() {
    widget.vaultLockNotifier.removeListener(_onLockSignal);
    super.dispose();
  }

  void _onLockSignal() {
    if (widget.vaultLockNotifier.value == true) {
      // reset signal
      widget.vaultLockNotifier.value = false;

      // force rebuild → unlock screen shown
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1️⃣ First-time user → setup
    if (!widget.user.vaultSetupComplete) {
      return VaultSetupScreen(user: widget.user);
    }

    // 2️⃣ Default vault entry → unlock
    return VaultUnlockScreen(user: widget.user);
  }
}
