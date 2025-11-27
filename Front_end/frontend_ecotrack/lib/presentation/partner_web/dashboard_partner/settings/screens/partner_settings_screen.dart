import 'package:flutter/material.dart';

class PartnerSettingsScreen extends StatelessWidget {
  const PartnerSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Cài Đặt Đối Tác',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5EAC24),
        ),
      ),
    );
  }
}

