import 'package:flutter/material.dart';
import '../core/theme.dart';

class SecurityFeed extends StatelessWidget {
  const SecurityFeed({super.key});

  final List<String> threats = const [
    "WARNING: Zero-day vulnerability found in Android WebView.",
    "ALERT: Phishing attacks targeting banking apps up by 300%.",
    "UPDATE: Patch available for Bluetooth protocol exploit.",
    "INFO: New malware 'Godfather' stealing crypto credentials.",
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CyberTheme.surface, // ✅ Fixed: cardColor -> surface
        border: Border(
            left: BorderSide(color: CyberTheme.dangerRed, width: 4) // ✅ Fixed: danger -> dangerRed
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
              "LIVE THREAT FEED",
              style: TextStyle(
                  color: CyberTheme.dangerRed, // ✅ Fixed: danger -> dangerRed
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5
              )
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 60,
            child: ListView.builder(
              itemCount: threats.length,
              itemBuilder: (ctx, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.grey, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          threats[index],
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}