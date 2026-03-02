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
  int selectedTab = 0;

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
      backgroundColor: const Color(0xFFF2F8F2), 
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFFC6E5C3),
          leadingWidth: 36, 
          leading: IconButton(
            padding: EdgeInsets.zero, 
            constraints: const BoxConstraints(), 
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 20), 
            onPressed: () => Navigator.pop(context),
          ),
          titleSpacing: 0, 
          centerTitle: false, 
          title: const Text(
            "Danh sách chiến dịch",
            style: TextStyle(
              color: Colors.black, 
              fontWeight: FontWeight.w800, 
              fontSize: 15
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Icon(Icons.eco, color: const Color(0xFF1F5C28)),
                  const SizedBox(width: 4),
                  Text(
                    "EcoTrack",
                    style: TextStyle(
                      color: const Color(0xFF1F5C28), 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1F5C28)), // Đã thay đổi
            );
          }

          final campaigns = _getFilteredCampaigns();

          return Column(
            children: [
              _buildTabs(),
              Expanded(
                child: campaigns.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: campaigns.length,
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

Widget _buildTabs() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAEFF0),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          Expanded(child: _tab("Tất cả", 0)),
          Expanded(child: _tab("Đang diễn ra", 1)),
          Expanded(child: _tab("Sắp tới", 2)),
        ],
      ),
    );
  }

Widget _tab(String title, int index) {
    final isActive = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      behavior: HitTestBehavior.opaque, 
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFC6E5C3) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        alignment: Alignment.center, // Căn giữa chữ
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : const Color(0xFF757575),
            // Tăng kích thước chữ lên một chút cho cân đối với dạng thanh mới
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  List<CampaignModel> _getFilteredCampaigns() {
    if (selectedTab == 1) return controller.activeCampaigns;
    if (selectedTab == 2) return controller.upcomingCampaigns;
    return [...controller.activeCampaigns, ...controller.upcomingCampaigns];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: const Color(0xFFC6E5C3), 
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có chiến dịch nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              "Hãy quay lại sau hoặc kiểm tra danh mục khác nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}