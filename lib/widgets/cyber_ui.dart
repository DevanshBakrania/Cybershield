import 'package:flutter/material.dart';
import '../core/theme.dart'; // ✅ FIXED: Points to lib/core/theme.dart

class CyberButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final bool isSecondary;

  const CyberButton({super.key, required this.text, required this.onTap, this.isSecondary = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSecondary ? CyberTheme.surface : CyberTheme.neonGreen,
          foregroundColor: isSecondary ? CyberTheme.textWhite : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
      ),
    );
  }
}

class CyberContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const CyberContainer({super.key, required this.child, this.height, this.padding, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: CyberTheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: child,
      ),
    );
  }
}

class CyberNeonText extends StatelessWidget {
  final String text;
  final double size;

  const CyberNeonText(this.text, {super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size,
        fontWeight: FontWeight.bold,
        color: CyberTheme.textWhite,
        shadows: [Shadow(color: CyberTheme.neonGreen.withValues(alpha: 0.6), blurRadius: 12, offset: const Offset(0, 0))],
      ),
    );
  }
}