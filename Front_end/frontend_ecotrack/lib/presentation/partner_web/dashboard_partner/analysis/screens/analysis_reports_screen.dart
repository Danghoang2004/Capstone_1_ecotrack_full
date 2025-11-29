import 'package:flutter/material.dart';

class AnalysisReportsScreen extends StatelessWidget {
  const AnalysisReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Phân Tích & Báo Cáo',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5EAC24),
        ),
      ),
    );
  }
}

