import 'package:flutter/material.dart';

class InfoHeader extends StatelessWidget {
  final String title;
  const InfoHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 1.5,
        ),
      ),
    );
  }
}

class InfoTile extends StatelessWidget {
  final String label;
  final String value;
  const InfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0D3A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        title: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}