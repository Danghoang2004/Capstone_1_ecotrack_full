import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    controller = RankingController();
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
    return Scaffold(
      backgroundColor: HomeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header (ẩn khi hideHeader = true)
            if (!widget.hideHeader) const RankingHeader(),
            // Tabs
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

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3C9541) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.white : Colors.grey[700],
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
