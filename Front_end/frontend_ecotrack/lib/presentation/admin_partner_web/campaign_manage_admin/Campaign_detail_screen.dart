import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';

class CampaignDetailScreen extends StatelessWidget {
  final int id;
  const CampaignDetailScreen(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    final api = CampaignApi(ApiClient(storage: const FlutterSecureStorage()));

    return FutureBuilder<Campaign>(
      future: api.getDetail(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final c = snapshot.data!;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(c.description ?? "Không có mô tả"),
              const SizedBox(height: 16),
              Text("📍 ${c.location}"),
              Text("🎁 ${c.rewardPoints} điểm"),
              if (c.qrCodeUrl != null) Image.network(c.qrCodeUrl!, height: 200),
            ],
          ),
        );
      },
    );
  }
}
