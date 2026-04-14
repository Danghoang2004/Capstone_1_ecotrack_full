import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_dashboard.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_list.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_panel.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_side_panel.dart';

class AdminCampaignPage extends StatefulWidget {
  const AdminCampaignPage({super.key});

  @override
  State<AdminCampaignPage> createState() => _AdminCampaignPageState();
}

class _AdminCampaignPageState extends State<AdminCampaignPage> {
  CampaignPanel panel = CampaignPanel.none;
  int? selectedId;
  int _refreshKey = 0;

  void openCreate() => setState(() {
    panel = CampaignPanel.create;
    selectedId = null;
  });

  void openEdit(int id) => setState(() {
    panel = CampaignPanel.edit;
    selectedId = id;
  });

  void openDetail(int id) => setState(() {
    panel = CampaignPanel.detail;
    selectedId = id;
  });

  void closePanel() => setState(() {
    panel = CampaignPanel.none;
    selectedId = null;
  });

  void refreshData() {
    setState(() {
      _refreshKey++; // Thay đổi key sẽ khiến CampaignList tạo lại hoặc reload
      panel = CampaignPanel.none; // Đóng panel chuyên nghiệp
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1320),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _AdminAccentChipCampaign(),
                          SizedBox(height: 10),
                          Text(
                            "Quản Lý Chiến Dịch",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Tạo, chỉnh sửa và theo dõi các chiến dịch thực tế",
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.adminTextSecondary,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: openCreate,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text("Tạo chiến dịch mới"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminAccentDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.adminAccentDeep.withValues(alpha: 0.28),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const CampaignDashboard(),
                  const SizedBox(height: 16),
                  CampaignList(
                    key: ValueKey(_refreshKey), // Gán key ở đây
                    showHeader: false,
                    onCreate: openCreate,
                    onEdit: openEdit,
                    onView: openDetail,
                  ),
                ],
              ),
            ),
          ),
        ),

        if (panel != CampaignPanel.none)
          CampaignSidePanel(
            panel: panel,
            campaignId: selectedId,
            onClose: closePanel,
            onSuccess: refreshData,
          ),
      ],
    );
  }
}

class _AdminAccentChipCampaign extends StatelessWidget {
  const _AdminAccentChipCampaign();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.adminAccentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'EcoTrack Admin',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.adminAccentDeep,
        ),
      ),
    );
  }
}
