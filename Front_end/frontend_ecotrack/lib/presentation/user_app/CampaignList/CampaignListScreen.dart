import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart';
import 'package:frontend_ecotrack/presentation/user_app/CampaignList/CampaignListCard.dart';
import 'package:frontend_ecotrack/presentation/user_app/Home/controllers/campaign_takes_place_controller.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  late CampaignTakesPlaceController controller;
  int selectedTab = 0; // 0: all, 1: active, 2: upcoming

  @override
  void initState() {
    super.initState();

    final apiClient = ApiClient(storage: const FlutterSecureStorage());

    controller = CampaignTakesPlaceController(CampaignRepository(apiClient));

    controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Danh sách chiến dịch",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final campaigns = _getFilteredCampaigns();

          return Column(
            children: [
              _buildTabs(),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: campaigns.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) =>
                      CampaignListCard(campaign: campaigns[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<CampaignModel> _getFilteredCampaigns() {
    if (selectedTab == 1) return controller.activeCampaigns;
    if (selectedTab == 2) return controller.upcomingCampaigns;
    return [...controller.activeCampaigns, ...controller.upcomingCampaigns];
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _tab("Tất cả", 0),
          const SizedBox(width: 8),
          _tab("Đang diễn ra", 1),
          const SizedBox(width: 8),
          _tab("Sắp tới", 2),
        ],
      ),
    );
  }

  Widget _tab(String title, int index) {
    final isActive = selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green
                : const Color.fromARGB(255, 211, 210, 210),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
