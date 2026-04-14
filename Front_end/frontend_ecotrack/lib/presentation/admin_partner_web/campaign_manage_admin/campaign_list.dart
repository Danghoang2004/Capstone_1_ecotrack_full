import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';

class CampaignList extends StatefulWidget {
  final VoidCallback onCreate;
  final Function(int) onEdit;
  final Function(int) onView;
  final bool showHeader;

  const CampaignList({
    super.key,
    required this.onCreate,
    required this.onEdit,
    required this.onView,
    this.showHeader = true,
  });

  @override
  State<CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<CampaignList> {
  late CampaignApi _campaignApi;
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _campaignApi = CampaignApi(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      _campaignsFuture = _campaignApi.fetchCampaigns();
    });
  }

  // 1. Overlay thông báo xóa thành công (Tự đóng)
  void _showDeleteSuccessOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(ctx).canPop()) Navigator.of(ctx).pop();
        });
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, color: Colors.redAccent, size: 64),
                SizedBox(height: 16),
                Text(
                  "Đã xóa!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  "Chiến dịch đã được loại bỏ khỏi hệ thống.",
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 2. Hàm xóa chiến dịch với Dialog xác nhận ở giữa
  Future<void> _deleteCampaign(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange,
                size: 60,
              ),
              const SizedBox(height: 16),
              const Text(
                "Xác nhận xóa",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                "Bạn có chắc chắn muốn xóa chiến dịch này không? Hành động này không thể hoàn tác.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: Colors.grey),
                      ),
                      child: const Text(
                        "Hủy bỏ",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Xác nhận xóa",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await _campaignApi.delete(id);
        if (mounted) {
          _showDeleteSuccessOverlay(context); // Hiển thị overlay thành công
          _refreshList(); // Tải lại danh sách
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showHeader) ...[
          _buildHeader(),
          const SizedBox(height: 24),
        ],
        _buildSearchBar(),
        const SizedBox(height: 20),
        FutureBuilder<List<Campaign>>(
          future: _campaignsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }
            if (snapshot.hasError)
              return Center(child: Text("Lỗi: ${snapshot.error}"));
            if (!snapshot.hasData || snapshot.data!.isEmpty)
              return const Center(child: Text("Không có chiến dịch nào"));

            return Column(
              children: snapshot.data!
                  .map(
                    (campaign) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildCampaignCard(campaign),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  // --- Các Widget thành phần đã được tách ra cho gọn ---

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Quản Lý Chiến Dịch",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8,
                color: AppColors.adminTextPrimary,
              ),
            ),
            Text(
              "Tạo, chỉnh sửa và theo dõi các chiến dịch thực tế",
              style: TextStyle(fontSize: 17, color: AppColors.adminTextSecondary),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: widget.onCreate,
            icon: const Icon(Icons.add, size: 18),
            label: const Text("Tạo chiến dịch mới"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: "Tìm kiếm chiến dịch...",
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.adminSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminAccent, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildCampaignCard(Campaign c) {
    final now = DateTime.now();
    final start = DateTime.tryParse(c.startDate) ?? now;
    String status = now.isAfter(start) ? "Đang diễn ra" : "Sắp diễn ra";
    Color statusColor = now.isAfter(start) ? Colors.green : Colors.blue;
    double progress = (c.maxParticipants > 0)
        ? (c.currentParticipants / c.maxParticipants).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    _statusBadge(status, statusColor),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onView(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.adminAccentSky.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.visibility_outlined,
                        color: AppColors.adminAccentSky,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => widget.onEdit(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurfaceMuted,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.edit_note,
                        color: AppColors.adminTextSecondary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => _deleteCampaign(c.id),
                    icon: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            c.description ?? "Không có mô tả",
            maxLines: 2,
            style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(c),
          const SizedBox(height: 24),
          Wrap(
            spacing: 28,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 280,
                child: _buildStatItem(
                  "Người tham gia",
                  "${c.currentParticipants}/${c.maxParticipants}",
                  progress,
                  AppColors.adminAccentSky,
                ),
              ),
              SizedBox(
                width: 280,
                child: _buildStatItem(
                  "Kinh phí",
                  "15.000.000 đ",
                  0.75,
                  AppColors.adminAccent,
                ),
              ),
              SizedBox(
                width: 160,
                child: _buildSimpleStat(
                  "Điểm thưởng",
                  "${c.rewardPoints} điểm",
                  Icons.stars_rounded,
                  AppColors.adminAccentWarm,
                ),
              ),
              SizedBox(
                width: 220,
                child: _buildSimpleStat(
                  "Tổ chức",
                  c.partnerName ?? "Đang cập nhật...",
                  Icons.account_balance_outlined,
                  const Color(0xFF8E24AA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(Campaign c) {
    return Wrap(
      spacing: 20,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 16,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              c.location,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 16,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              "${c.startDate} - ${c.endDate}",
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    double progress,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.group_work_outlined, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              color: color,
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleStat(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
