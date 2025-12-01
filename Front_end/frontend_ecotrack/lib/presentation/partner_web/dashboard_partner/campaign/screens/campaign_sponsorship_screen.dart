import 'package:flutter/material.dart';

class CampaignSponsorshipScreen extends StatelessWidget {
  const CampaignSponsorshipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Tài Trợ Chiến Dịch',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5EAC24),
        ),
      ),
    );
  }
}

