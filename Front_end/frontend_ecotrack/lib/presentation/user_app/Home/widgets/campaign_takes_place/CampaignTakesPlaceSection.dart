import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart';
import 'package:frontend_ecotrack/presentation/user_app/home/controllers/campaign_takes_place_controller.dart';

class CampaignTakesPlaceSection extends StatefulWidget {
  final CampaignTakesPlaceController controller;

  const CampaignTakesPlaceSection({super.key, required this.controller});

  @override
  State<CampaignTakesPlaceSection> createState() =>
      _CampaignTakesPlaceSectionState();
}

class _CampaignTakesPlaceSectionState extends State<CampaignTakesPlaceSection> {
  CampaignTakesPlaceController get controller => widget.controller;

  Widget _buildCampaignImage(String imageUrl) {
    final bool hasValidUrl =
        imageUrl.trim().isNotEmpty &&
        (imageUrl.startsWith('http://') || imageUrl.startsWith('https://'));

    if (!hasValidUrl) {
      return _buildImagePlaceholder();
    }

    return Image.network(
      imageUrl,
      width: 110,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: 110,
      height: 80,
      color: Colors.green.shade50,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        size: 30,
        color: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader("Chiến dịch đang diễn ra", "Xem tất cả"),
              const SizedBox(height: 8),

              ...controller.activeCampaigns
                  .take(2) // 👉 muốn 2 thì đổi thành take(2)
                  .map(_buildCampaignCard),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/campaigns');
            },
            child: Text(
              action,
              style: const TextStyle(
                color: Color.fromARGB(255, 11, 11, 11),
                fontWeight: FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // 📌 CARD GIỐNG MẪU 100%
  // ===============================
  Widget _buildCampaignCard(CampaignModel c) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ảnh
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildCampaignImage(c.imageUrl),
          ),
          const SizedBox(width: 12),

          // Thông tin
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),

                Text(
                  c.dateTime,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 6),

                Row(
                  children: [
                    // Người tham gia
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.people_alt_rounded,
                            size: 16,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${c.participants} người tham gia",
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
