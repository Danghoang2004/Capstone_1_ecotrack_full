import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/campain.dart';

class CampaignList extends StatefulWidget {
  final VoidCallback onCreate;
  final Function(int) onEdit;
  final Function(int) onView;

  const CampaignList({
    super.key,
    required this.onCreate,
    required this.onEdit,
    required this.onView,
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
    // Khởi tạo API service
    _campaignApi = CampaignApi(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _refreshList();
  }

  void _refreshList() {
    setState(() {
      // Giả sử CampaignApi của bạn có hàm getAll() hoặc tương đương
      _campaignsFuture = _campaignApi.fetchCampaigns();
    });
  }

  Future<void> _deleteCampaign(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận xóa"),
        content: const Text("Bạn có chắc chắn muốn xóa chiến dịch này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _campaignApi.delete(id); // Giả sử có hàm delete(id)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đã xóa chiến dịch thành công")),
        );
        _refreshList(); // Tải lại danh sách sau khi xóa
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi xóa: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HEADER
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Quản Lý Chiến Dịch",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Tạo, chỉnh sửa và theo dõi các chiến dịch thực tế",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: widget.onCreate,
              icon: const Icon(Icons.add, size: 18),
              label: const Text("Tạo chiến dịch mới"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00BFA5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 15,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // SEARCH BAR (UI tạm thời, bạn có thể thêm logic filter sau)
        TextField(
          decoration: InputDecoration(
            hintText: "Tìm kiếm chiến dịch...",
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // DANH SÁCH DỮ LIỆU THẬT
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
            if (snapshot.hasError) {
              return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}"));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("Không có chiến dịch nào"));
            }

            return Column(
              children: snapshot.data!
                  .map((campaign) => _buildCampaignCard(campaign))
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCampaignCard(Campaign c) {
    // Logic xác định trạng thái dựa trên ngày tháng
    final now = DateTime.now();
    final start = DateTime.tryParse(c.startDate) ?? now;
    String status = "Sắp diễn ra";
    Color statusColor = Colors.blue;
    double progress = 0;
    if (c.maxParticipants > 0) {
      progress = c.currentParticipants / c.maxParticipants;
    }
    if (progress > 1.0) progress = 1.0;

    if (now.isAfter(start)) {
      status = "Đang diễn ra";
      statusColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
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
                    onPressed: () => widget.onView(c.id!),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      color: Colors.blueGrey,
                    ),
                    tooltip: "Xem chi tiết",
                  ),
                  IconButton(
                    onPressed: () => widget.onEdit(c.id!),
                    icon: const Icon(Icons.edit_note, color: Colors.grey),
                  ),
                  IconButton(
                    onPressed: () => _deleteCampaign(c.id!),
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            c.description ?? "Không có mô tả",
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                c.location,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(width: 20),
              const Icon(
                Icons.calendar_today_outlined,
                size: 16,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                "${c.startDate} - ${c.endDate}",
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SizedBox(
                width: 220,
                child: _buildStatItem(
                  "Người tham gia",
                  "${c.currentParticipants}/${c.maxParticipants}",
                  progress,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 150),
              SizedBox(
                width: 220,
                child: _buildStatItem(
                  "Kinh phí",
                  "15.000.000 đ",
                  0.75,
                  Colors.green,
                ),
              ),
              SizedBox(width: 150),
              _buildSimpleStat(
                "Điểm thưởng",
                "${c.rewardPoints} điểm",
                Icons.stars_rounded,
                Colors.orange,
              ),

              _buildSimpleStat(
                "Tổ chức",
                c.partnerName ?? "Đang cập nhật...",
                Icons.account_balance_outlined,
                Colors.purple,
              ),
            ],
          ),
        ],
      ),
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

  // Sửa lại hàm buildStatItem để giao diện giống hệt ảnh mẫu
  Widget _buildStatItem(
    String label,
    String value,
    double progress,
    Color color, {
    String? subtitle,
  }) {
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
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null)
            Text(
              subtitle,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 8),
          // Thanh tiến trình chạy theo % thật
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
          SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
