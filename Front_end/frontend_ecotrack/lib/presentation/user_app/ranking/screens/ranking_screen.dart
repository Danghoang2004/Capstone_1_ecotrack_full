import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/ranking_controller.dart';
import '../widgets/top_three_section.dart';
import '../widgets/ranking_list_section.dart';
import '../widgets/header.dart';

class RankingScreen extends StatefulWidget {
  final bool hideHeader;

  const RankingScreen({super.key, this.hideHeader = false});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late final RankingController controller;
  int _selectedTab = 0; // 0: Cá Nhân, 1: Nhóm
  late final ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient(storage: const FlutterSecureStorage());
    controller = RankingController(_apiClient);
    _loadData();
  }

  Future<void> _loadData() async {
    await controller.loadIndividualRankings();
    await controller.loadGroupRankings();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hideHeader) {
      // Desktop: Không dùng Scaffold, chỉ hiển thị content với scroll
      return Container(
        color: const Color(0xFFF4FBF8),
        child: Column(
          children: [
            // Tabs
            _buildTabs(),
            // Content với scroll
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Top 3 Section
                    TopThreeSection(
                      controller: controller,
                      isIndividual: _selectedTab == 0,
                    ),
                    const SizedBox(height: 24),
                    // Ranking List Section
                    RankingListSection(
                      controller: controller,
                      isIndividual: _selectedTab == 0,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile: Dùng Scaffold và SafeArea
      return Scaffold(
        backgroundColor: const Color(0xFFF4FBF8),
        appBar: const RankingHeader(),
        body: SafeArea(
          child: Column(
            children: [
              _buildTabs(),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    children: [
                      // Top 3 Section
                      TopThreeSection(
                        controller: controller,
                        isIndividual: _selectedTab == 0,
                      ),
                      const SizedBox(height: 24),
                      // Ranking List Section
                      RankingListSection(
                        controller: controller,
                        isIndividual: _selectedTab == 0,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildTabs() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: widget.hideHeader ? 16 : 8,
      ),
      child: Row(
        children: [
          Expanded(child: _buildTab('Cá Nhân', 0)),
          const SizedBox(width: 8),
          Expanded(child: _buildTab('Nhóm', 1)),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    const selectedColor = Color(0xFF2F8F46);
    const unselectedColor = Color(0xFFE6F1EB);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? selectedColor : const Color(0xFFCDE1D7),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : const Color(0xFF4B655A),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
