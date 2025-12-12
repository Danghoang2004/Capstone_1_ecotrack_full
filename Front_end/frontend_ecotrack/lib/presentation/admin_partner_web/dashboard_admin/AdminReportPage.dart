import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:frontend_ecotrack/data/utils/ImageUtils.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  final ReportService _reportService = ReportService();
  final TextEditingController _searchController = TextEditingController();
  final ApiClient apiClient = ApiClient(storage: const FlutterSecureStorage());
  List<Report> _reports = [];
  List<Report> _filteredReports = [];
  bool _isLoading = true;

  // Bộ lọc
  String _selectedStatus = 'ALL';
  String _selectedLevel = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  Future<void> _fetchReports() async {
    try {
      final data = await _reportService.fetchAllReports();
      if (mounted) {
        setState(() {
          _reports = data;
          _filterReports();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterReports() {
    setState(() {
      _filteredReports = _reports.where((report) {
        // Lọc theo trạng thái
        bool statusMatch =
            _selectedStatus == 'ALL' || report.status == _selectedStatus;

        // Lọc theo từ khóa tìm kiếm (Tiêu đề hoặc Mô tả)
        String query = _searchController.text.toLowerCase();
        bool searchMatch =
            query.isEmpty ||
            report.title.toLowerCase().contains(query) ||
            report.description.toLowerCase().contains(query);

        return statusMatch && searchMatch;
      }).toList();
    });
  }

  Future<void> _updateStatus(int reportId, String newStatus) async {
    bool success = await _reportService.updateReportStatus(reportId, newStatus);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Cập nhật thành công!")));
        _fetchReports();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lỗi cập nhật!"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8080";
    return "$baseUrl$path";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F5F5,
      ), // Màu nền xám nhạt giống thiết kế
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header Tiêu đề
            const Text(
              "Bản Đồ Báo Cáo Rác",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Theo dõi và quản lý các điểm báo cáo rác thải từ người dùng",
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // 2. Thống kê nhanh (Dashboard Stats)
            _buildStatCards(),
            const SizedBox(height: 32),

            // 3. Thanh công cụ (Search + Filter)
            _buildToolbar(),
            const SizedBox(height: 24),

            // 4. Danh sách báo cáo (List Items)
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReports.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Text("Không tìm thấy báo cáo nào"),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredReports.length,
                    separatorBuilder: (ctx, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (ctx, index) =>
                        _buildReportItem(_filteredReports[index]),
                  ),
          ],
        ),
      ),
    );
  }

  // Widget: Các thẻ thống kê (Chờ xử lý, Đã xác minh...)
  Widget _buildStatCards() {
    // Tính toán số liệu thực tế từ list _reports
    int pending = _reports.where((r) => r.status == 'PENDING').length;
    int verified = _reports.where((r) => r.status == 'VERIFIED').length;
    int cleaned = _reports.where((r) => r.status == 'CLEANED').length;
    int total = _reports.length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            "Chờ xử lý",
            "$pending",
            Icons.access_time,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            "Đã xác minh",
            "$verified",
            Icons.warning_amber_rounded,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            "Đã dọn dẹp",
            "$cleaned",
            Icons.check_circle_outline,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _statCard(
            "Tổng báo cáo",
            "$total",
            Icons.location_on_outlined,
            Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _statCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              Text(
                count,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget: Thanh tìm kiếm và bộ lọc
  Widget _buildToolbar() {
    return Row(
      children: [
        // Ô tìm kiếm
        Expanded(
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterReports(),
              decoration: const InputDecoration(
                hintText: "Tìm kiếm theo địa điểm, mô tả...",
                border: InputBorder.none,
                icon: Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),

        // Dropdown Trạng thái
        _buildDropdownButton(
          value: _selectedStatus,
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text("Tất cả trạng thái")),
            DropdownMenuItem(value: 'PENDING', child: Text("Chờ xử lý")),
            DropdownMenuItem(value: 'VERIFIED', child: Text("Đã xác minh")),
            DropdownMenuItem(value: 'CLEANED', child: Text("Đã dọn dẹp")),
            DropdownMenuItem(value: 'REJECTED', child: Text("Đã từ chối")),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedStatus = val;
                _filterReports();
              });
            }
          },
        ),
        const SizedBox(width: 16),

        // Dropdown Mức độ (Placeholder)
        _buildDropdownButton(
          value: _selectedLevel,
          items: const [
            DropdownMenuItem(value: 'ALL', child: Text("Tất cả mức độ")),
            DropdownMenuItem(value: 'HIGH', child: Text("Nghiêm trọng")),
            DropdownMenuItem(value: 'MEDIUM', child: Text("Trung bình")),
            DropdownMenuItem(value: 'LOW', child: Text("Thấp")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _selectedLevel = val);
          },
        ),
      ],
    );
  }

  Widget _buildDropdownButton({
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
          style: const TextStyle(color: Colors.black87, fontSize: 14),
        ),
      ),
    );
  }

  // Widget: Item Báo cáo (Giống thiết kế)
  Widget _buildReportItem(Report report) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng 1: Tiêu đề + Badge + Nút bấm
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          report.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildStatusBadge(report.status),
                        // Nếu có mức độ nghiêm trọng (ví dụ từ AI), hiển thị thêm badge ở đây
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Nút hành động
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () {
                      _showDetailDialog(report);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    child: const Text("Xem chi tiết"),
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(report),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Dòng 2: Thông tin người gửi, thời gian
          Row(
            children: [
              Icon(Icons.person_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                "Báo cáo bởi: Người dùng #${report.reportId}",
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ), // Thay bằng tên user thật nếu có
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 4),
              Text(
                DateFormat('HH:mm dd/MM/yyyy').format(report.createdAt),
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              const SizedBox(width: 16),
              if (report.imageUrl.isNotEmpty) ...[
                Icon(
                  Icons.camera_alt_outlined,
                  size: 16,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  "Có hình ảnh",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ],
          ),

          const SizedBox(height: 16),

          // Dòng 3: Tọa độ & Loại rác (Khối màu xám)
          Row(
            children: [
              _infoBox(
                Icons.location_on_outlined,
                "Tọa độ GPS",
                "${report.latitude}, ${report.longitude}",
              ),
              const SizedBox(width: 16),
              _infoBox(Icons.category_outlined, "Loại rác", report.category),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoBox(IconData icon, String label, String value) {
    return Container(
      width: 200,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.red),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label;
    IconData icon;

    switch (status) {
      case 'PENDING':
        bg = Colors.orange.withOpacity(0.1);
        text = Colors.orange;
        label = "Chờ xử lý";
        icon = Icons.access_time;
        break;
      case 'VERIFIED':
        bg = Colors.blue.withOpacity(0.1);
        text = Colors.blue;
        label = "Đã xác minh";
        icon = Icons.warning_amber_rounded;
        break;
      case 'CLEANED':
        bg = Colors.green.withOpacity(0.1);
        text = Colors.green;
        label = "Đã dọn dẹp";
        icon = Icons.check_circle_outline;
        break;
      case 'REJECTED':
        bg = Colors.red.withOpacity(0.1);
        text = Colors.red;
        label = "Từ chối";
        icon = Icons.cancel_outlined;
        break;
      default:
        bg = Colors.grey.withOpacity(0.1);
        text = Colors.grey;
        label = status;
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: text),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: text,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Report report) {
    if (report.status == 'PENDING') {
      return ElevatedButton(
        onPressed: () => _updateStatus(report.reportId, 'VERIFIED'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: const Text("Xác nhận"),
      );
    } else if (report.status == 'VERIFIED') {
      return ElevatedButton(
        onPressed: () => _updateStatus(report.reportId, 'CLEANED'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: const Text("Đã dọn xong"),
      );
    }
    return const SizedBox.shrink(); // Đã dọn hoặc từ chối thì không hiện nút chính
  }

  // Hàm hiển thị Popup chi tiết
  void _showDetailDialog(Report report) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: Colors.white,
        child: Container(
          width: 600, // Chiều rộng cố định cho đẹp trên Web
          padding: const EdgeInsets.all(0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header ảnh
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                    child: Image.network(
                      ImageUtils.buildUrl(report.imageUrl),
                      height: 250,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 250,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image, size: 50),
                      ),
                    ),
                  ),
                ],
              ),

              // 2. Nội dung chi tiết
              Flexible(
                // Cho phép cuộn nếu nội dung dài
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge trạng thái + Ngày giờ
                      Row(
                        children: [
                          _buildStatusBadge(report.status),
                          const Spacer(),
                          Text(
                            DateFormat(
                              'HH:mm - dd/MM/yyyy',
                            ).format(report.createdAt),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Tiêu đề
                      Text(
                        report.title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Thông tin chi tiết (Grid 2 cột)
                      Wrap(
                        spacing: 20,
                        runSpacing: 20,
                        children: [
                          _detailItem(
                            Icons.person,
                            "Người báo cáo",
                            "User #${report.reportId}",
                          ), // Thay ID thật nếu có
                          _detailItem(
                            Icons.category,
                            "Loại rác",
                            report.category,
                          ),
                          _detailItem(
                            Icons.location_on,
                            "Tọa độ",
                            "${report.latitude}, ${report.longitude}",
                          ),
                          if (report.aiConfidence != null)
                            _detailItem(
                              Icons.smart_toy,
                              "Độ tin cậy AI",
                              "${(report.aiConfidence! * 100).toStringAsFixed(1)}%",
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const SizedBox(height: 10),

                      // Mô tả
                      const Text(
                        "Mô tả chi tiết:",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        report.description.isEmpty
                            ? "Không có mô tả"
                            : report.description,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),

              // 3. Footer Nút hành động (Duyệt/Xóa ngay trong popup)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Đóng",
                        style: TextStyle(
                          color: Color.fromARGB(255, 54, 54, 54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (report.status == 'PENDING') ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cancel, size: 18),
                        label: const Text("Từ chối"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'REJECTED');
                          Navigator.pop(ctx);
                        },
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text("Duyệt bài"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'VERIFIED');
                          Navigator.pop(ctx);
                        },
                      ),
                    ],
                    if (report.status == 'VERIFIED')
                      ElevatedButton.icon(
                        icon: const Icon(Icons.cleaning_services, size: 18),
                        label: const Text("Đã dọn xong"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          _updateStatus(report.reportId, 'CLEANED');
                          Navigator.pop(ctx);
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailItem(IconData icon, String label, String value) {
    return Container(
      width: 250, // Độ rộng mỗi mục
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
