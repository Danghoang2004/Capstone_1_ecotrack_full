import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';

class CampaignDetailView extends StatelessWidget {
  final int id;
  const CampaignDetailView({super.key, required this.id});

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
          child: ListView(
            children: [
              Text(
                c.title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _item("Mô tả", c.description ?? "Không có"),
              _item("Địa điểm", c.location),
              _item("Thời gian", "${c.startDate} → ${c.endDate}"),
              _item(
                "Số người tham gia",
                "${c.currentParticipants}/${c.maxParticipants}",
              ),
              _item("Số người tối đa", c.maxParticipants.toString()),
              _item("Điểm thưởng", "${c.rewardPoints} điểm"),

              const SizedBox(height: 16),

              if (c.imageUrl != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Ảnh chiến dịch",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(c.imageUrl!),
                    ),
                  ],
                ),

              if (c.qrCodeUrl != null) ...[
                const SizedBox(height: 24),
                const Text(
                  "QR Check-in",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Center(child: Image.network(c.qrCodeUrl!, height: 200)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _item(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
