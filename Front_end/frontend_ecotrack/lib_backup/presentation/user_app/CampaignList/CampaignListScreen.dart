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
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Khám phá chiến dịch",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800 , fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.loading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
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
                        padding: const EdgeInsets.all(20),
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
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _tab("Tất cả", 0),
            const SizedBox(width: 12),
            _tab("Đang diễn ra", 1),
            const SizedBox(width: 12),
            _tab("Sắp tới", 2),
          ],
        ),
      ),
    );
  }

  Widget _tab(String title, int index) {
    final isActive = selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? Colors.green : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: Colors.green.withOpacity(0.25),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  List<CampaignModel> _getFilteredCampaigns() {
    if (selectedTab == 1) return controller.activeCampaigns;
    if (selectedTab == 2) return controller.upcomingCampaigns;
    // Mặc định trả về tất cả
    return [...controller.activeCampaigns, ...controller.upcomingCampaigns];
  }

  // --- HÀM GIAO DIỆN TRỐNG (Sửa lỗi undefined _buildEmptyState) ---
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có chiến dịch nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Hãy quay lại sau hoặc kiểm tra danh mục khác nhé!",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
