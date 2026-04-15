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
    // Khởi tạo các service
    final apiClient = ApiClient(storage: const FlutterSecureStorage());
    controller = CampaignTakesPlaceController(CampaignRepository(apiClient));
    // Gọi API lấy dữ liệu thực tế
    controller.loadData();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Danh Sách Chiến dịch",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        color: const Color(0xFFF4FBF8),
        child: SafeArea(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              // 1. TRẠNG THÁI LOADING THỰC TẾ
              if (controller.loading) {
                return const Center(
                  child: CircularProgressIndicator(color: Colors.green),
                );
              }

              // 2. LẤY DỮ LIỆU ĐÃ LỌC
              final campaigns = _getFilteredCampaigns();

              // 3. HIỂN THỊ GIAO DIỆN CHÍNH
              return Column(
                children: [
                  _buildTabs(),
                  Expanded(
                    child: campaigns.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: () async => controller.loadData(),
                            color: Colors.green,
                            child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                bottom: 20,
                                top: 10,
                              ),
                              itemCount: campaigns.length,
                              itemBuilder: (_, i) =>
                                  CampaignListCard(campaign: campaigns[i]),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF386641)
              : Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.grey.shade300,
            width: 1,
          ),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: const Color(0xFF386641).withOpacity(0.3),
                blurRadius: 8,
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

  // --- HÀM LẤY DỮ LIỆU TỪ API THẬT QUA CONTROLLER ---
  List<CampaignModel> _getFilteredCampaigns() {
    if (selectedTab == 1) return controller.activeCampaigns;
    if (selectedTab == 2) return controller.upcomingCampaigns;
    // Tab 0: Trả về tất cả
    return [...controller.activeCampaigns, ...controller.upcomingCampaigns];
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.nature_people_outlined,
            size: 80,
            color: Colors.green.shade200,
          ),
          const SizedBox(height: 16),
          Text(
            "Chưa có chiến dịch nào",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              "Hãy quay lại sau hoặc kiểm tra danh mục khác nhé!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
