import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/core/services/partner_service.dart';
import 'package:frontend_ecotrack/data/models/partner_dashboard_models.dart';

const Color primaryGreen = Color(0xFF06923E);

class PartnerDashboardScreen extends StatefulWidget {
  final PartnerApi api;

  const PartnerDashboardScreen({super.key, required this.api});

  @override
  State<PartnerDashboardScreen> createState() => _PartnerDashboardScreenState();
}

class _PartnerDashboardScreenState extends State<PartnerDashboardScreen> {
  final AuthService _authService = AuthService();
  late Future<PartnerSponsorshipDashboard> _future;

  // controller cho dialog tạo tài trợ
  final TextEditingController _campaignNameCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchDashboard();
  }

  @override
  void dispose() {
    _campaignNameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E88E5),
        title: const Text("EcoTrack Partner Portal"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  "/admin_login",
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: FutureBuilder<PartnerSponsorshipDashboard>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Lỗi: ${snapshot.error}"));
                  }
                  final data = snapshot.data!;
                  return _buildContent(data);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SIDEBAR ----------------

  Widget _buildSidebar() {
    return Container(
      width: 230,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _sidebarItem(Icons.dashboard_outlined, "Dashboard", false),
          _sidebarItem(Icons.card_giftcard_outlined, "Quản Lý Coupon", false),
          _sidebarItem(Icons.campaign_outlined, "Tài Trợ Chiến Dịch", true),
          _sidebarItem(Icons.analytics_outlined, "Báo Cáo", false),
        ],
      ),
    );
  }

  Widget _sidebarItem(IconData icon, String label, bool active) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFE8F7ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: active ? primaryGreen : Colors.grey.shade600,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: active ? primaryGreen : Colors.grey.shade800,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  // ---------------- MAIN CONTENT ----------------

  Widget _buildContent(PartnerSponsorshipDashboard data) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4 box thống kê đầu trang
          Row(
            children: [
              Expanded(
                child: _statCard(
                  "Tổng Doanh Thu",
                  "${data.totalRevenue.toStringAsFixed(0)}đ",
                  Icons.attach_money,
                  "+18%",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  "Coupon Hoạt Động",
                  "${data.activeCoupons}",
                  Icons.confirmation_number,
                  "+5",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  "Lượt Sử Dụng Coupon",
                  "${data.couponUsage}",
                  Icons.people,
                  "+23%",
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _statCard(
                  "ROI",
                  "${data.avgRoi}%",
                  Icons.trending_up,
                  "+12%",
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // tiêu đề + nút tạo chiến dịch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Tài Trợ Chiến Dịch",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Hỗ trợ các chiến dịch môi trường và theo dõi ROI",
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _openCreateSponsorshipDialog,
                icon: const Icon(Icons.add),
                label: const Text("Tạo Chiến Dịch"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // danh sách campaign
          Column(children: data.campaigns.map(_campaignCard).toList()),
        ],
      ),
    );
  }

  // ---------------- DIALOG TẠO TÀI TRỢ ----------------

  void _openCreateSponsorshipDialog() {
    _campaignNameCtrl.clear();
    _amountCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Tài Trợ Chiến Dịch Mới",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Tên Chiến Dịch",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _campaignNameCtrl,
                    decoration: InputDecoration(
                      hintText: "Nhập tên chiến dịch",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Số Tiền Tài Trợ (VND)",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "Nhập số tiền",
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text("Hủy"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          final name = _campaignNameCtrl.text.trim();
                          final amount = _amountCtrl.text.trim();

                          if (name.isEmpty || amount.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Vui lòng nhập đầy đủ thông tin.",
                                ),
                              ),
                            );
                            return;
                          }

                          // TODO: Gọi API tạo chiến dịch tài trợ
                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text("Tài Trợ"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- DIALOG CHỈNH SỬA CHIẾN DỊCH ----------------

  void _openEditCampaignDialog(PartnerCampaignSummary c) {
    final TextEditingController nameCtrl = TextEditingController(text: c.title);

    String statusValue = c.statusDisplay; // "đang diễn ra" hoặc "đã kết thúc"

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chỉnh Sửa: ${c.title}",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    "Tên Chiến Dịch",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    "Trạng Thái",
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: statusValue,
                    items: const [
                      DropdownMenuItem(
                        value: "đang diễn ra",
                        child: Text("đang diễn ra"),
                      ),
                      DropdownMenuItem(
                        value: "đã kết thúc",
                        child: Text("đã kết thúc"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        statusValue = val;
                      }
                    },
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 12,
                          ),
                          foregroundColor: Colors.black87,
                          backgroundColor: Colors.grey.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text("Hủy"),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          // CẬP NHẬT LẠI ĐỐI TƯỢNG + setState
                          setState(() {
                            c.title = nameCtrl.text.trim();
                            c.statusDisplay = statusValue;
                          });

                          Navigator.of(ctx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text("Lưu"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ---------------- CÁC WIDGET PHỤ ----------------

  Widget _statCard(String title, String value, IconData icon, String percent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.07),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFFE8F7ED),
            child: Icon(icon, color: primaryGreen),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  percent,
                  style: const TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // CARD CHIẾN DỊCH – giống hình 1, KHÔNG gọi điểm, có nút chỉnh sửa
  Widget _campaignCard(PartnerCampaignSummary c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            blurRadius: 5,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: Row(
        children: [
          // icon bên trái
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE8F7ED),
            child: const Icon(Icons.center_focus_strong, color: primaryGreen),
          ),
          const SizedBox(width: 16),

          // tiêu đề + dòng phụ
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${c.participants} người tham gia • Tài trợ: ${c.sponsorshipAmount.toStringAsFixed(0)}đ",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),

          // ROI + status + nút edit
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "ROI: ${c.roiPercent.toStringAsFixed(0)}%",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.statusDisplay == "đã kết thúc"
                      ? Colors.grey.shade300
                      : const Color(0xFFE8F7ED),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  c.statusDisplay,
                  style: TextStyle(
                    color: c.statusDisplay == "đã kết thúc"
                        ? Colors.grey.shade800
                        : primaryGreen,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            onPressed: () {
              _openEditCampaignDialog(c);
            },
          ),
        ],
      ),
    );
  }
}
