import 'package:flutter/material.dart';

class StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final bool compact;

  const StatItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: compact ? 14 : 16, color: iconColor),
        SizedBox(width: compact ? 4 : 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 13 : 15,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: compact ? 9 : 11,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

