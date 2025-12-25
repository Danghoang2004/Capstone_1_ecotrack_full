import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_dashboard.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_list.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_side_panel.dart';

enum CampaignPanel { none, create, edit, detail }

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
          child: Column(
            children: [
              const CampaignDashboard(),
              const SizedBox(height: 16),
              CampaignList(
                key: ValueKey(_refreshKey), // Gán key ở đây
                onCreate: openCreate,
                onEdit: openEdit,
                onView: openDetail,
              ),
            ],
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
