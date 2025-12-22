import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/AdminCampainPage.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/campaign_detail_view.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/create_campaign_form.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/campaign_manage_admin/edit_campaign_form.dart';

class CampaignSidePanel extends StatelessWidget {
  final CampaignPanel panel;
  final int? campaignId;
  final VoidCallback onClose;

  const CampaignSidePanel({
    super.key,
    required this.panel,
    this.campaignId,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Sử dụng Center để căn giữa màn hình
    return Center(
      child: Material(
        color: Colors.transparent,
        // 2. Tạo Container với bo góc và đổ bóng
        child: Container(
          width: 600, // Chiều rộng cố định cho dialog (có thể điều chỉnh)
          height:
              600, // Chiều cao cố định (có thể dùng constraints nếu muốn linh hoạt hơn)
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16), // Bo góc 16px
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          // 3. Bố cục Column: Header ở trên, Content ở dưới
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- HEADER CỦA DIALOG ---
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _getPanelTitle(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onClose,
                      tooltip: 'Đóng',
                    ),
                  ],
                ),
              ),
              const Divider(height: 1), // Đường kẻ phân cách header
              // --- NỘI DUNG FORM ---
              Expanded(
                // Sử dụng ClipRRect để nội dung không bị tràn ra khỏi góc bo của Container
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                  child: _buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm helper để lấy tiêu đề dựa trên loại panel
  String _getPanelTitle() {
    switch (panel) {
      case CampaignPanel.create:
        return 'Tạo Chiến Dịch Mới';
      case CampaignPanel.edit:
        return 'Chỉnh Sửa Chiến Dịch';
      case CampaignPanel.detail:
        return 'Chi Tiết Chiến Dịch';
      default:
        return '';
    }
  }

  Widget _buildContent() {
    // Lưu ý: Các form con (CreateCampaignForm, v.v.) nên tự quản lý padding của chúng
    // hoặc bạn có thể thêm Padding bọc ngoài ở đây nếu cần.
    switch (panel) {
      case CampaignPanel.create:
        return const CreateCampaignForm();
      case CampaignPanel.edit:
        return EditCampaignForm(id: campaignId!);
      case CampaignPanel.detail:
        return CampaignDetailView(id: campaignId!);
      default:
        return const SizedBox();
    }
  }
}
