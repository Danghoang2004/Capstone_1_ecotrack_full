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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // MAIN CONTENT
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const CampaignDashboard(),
              const SizedBox(height: 16),
              CampaignList(
                onCreate: openCreate,
                onEdit: openEdit,
                onView: openDetail,
              ),
            ],
          ),
        ),

        // SIDE PANEL
        if (panel != CampaignPanel.none)
          CampaignSidePanel(
            panel: panel,
            campaignId: selectedId,
            onClose: closePanel,
          ),
      ],
    );
  }
}
