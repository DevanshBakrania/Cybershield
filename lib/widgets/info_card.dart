import 'package:flutter/material.dart';
import '../core/theme.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  const InfoCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
    this.color
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: CyberTheme.surface, // ✅ Fixed: cardColor -> surface
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: (color ?? CyberTheme.neonGreen).withValues(alpha: 0.3) // ✅ Fixed: accent -> neonGreen
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Icon(icon, color: color ?? CyberTheme.neonGreen), // ✅ Fixed: accent -> neonGreen
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 10)),
            Text(
                value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                ),
                overflow: TextOverflow.ellipsis
            ),
          ],
        ),
      ),
    );
  }
}