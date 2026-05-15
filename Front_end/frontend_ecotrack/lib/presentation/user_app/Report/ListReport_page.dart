import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:intl/intl.dart';
import '../../../core/services/ReportService.dart';
import 'ReportDetailPage.dart';

class ListReportPage extends StatefulWidget {
  const ListReportPage({super.key});

  @override
  State<ListReportPage> createState() => _ListReportPageState();
}

class _ListReportPageState extends State<ListReportPage> {
  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  late Future<List<Report>> _reportsFuture;

  @override
  void initState() {
    super.initState();
    _reportsFuture = _reportService.fetchMyReports();
  }

  Future<void> _refreshReports() async {
    setState(() {
      _reportsFuture = _reportService.fetchMyReports();
    });
  }

  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8080";
    return "$baseUrl$path";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFB74D);
      case 'PENDING_AI_ANALYSIS':
        return const Color(0xFFFFB74D);
      case 'VERIFIED':
        return const Color(0xFF42A5F5);
      case 'AI_VERIFIED':
        return const Color(0xFF1E88E5);
      case 'NEED_REVIEW':
        return const Color(0xFFFB8C00);
      case 'REQUEST_REUPLOAD':
        return const Color(0xFFF4511E);
      case 'CLEANED':
        return const Color(0xFF66BB6A);
      case 'APPROVED':
        return const Color(0xFF2E7D32);
      case 'REJECTED':
        return const Color(0xFFEF5350);
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'PENDING':
        return 'Đang xử lý';
      case 'PENDING_AI_ANALYSIS':
        return 'Đang phân tích AI';
      case 'VERIFIED':
        return 'Đã xác thực';
      case 'AI_VERIFIED':
        return 'AI đã xác thực';
      case 'NEED_REVIEW':
        return 'Cần kiểm duyệt';
      case 'REQUEST_REUPLOAD':
        return 'Cần chụp lại';
      case 'CLEANED':
        return 'Đã dọn dẹp';
      case 'APPROVED':
        return 'Đã duyệt';
      case 'REJECTED':
        return 'Từ chối';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      // APPBAR VỚI KÍCH THƯỚC TIÊU CHUẨN
      appBar: AppBar(
        title: const Text(
          "Lịch sử báo cáo",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pushNamed(context, '/user_app'),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF2E7D32),
        onRefresh: _refreshReports,
        child: FutureBuilder<List<Report>>(
          future: _reportsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              );
            } else if (snapshot.hasError) {
              return Center(child: Text("Có lỗi xảy ra: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final reports = snapshot.data!;
            reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              itemCount: reports.length,
              itemBuilder: (context, index) => _buildReportCard(reports[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.eco_rounded,
                size: 80,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Chưa có dấu chân xanh nào!",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            const Text("Hãy bắt đầu báo cáo để bảo vệ môi trường nhé."),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(Report report) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Bo góc hiện đại
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReportDetailPage(report: report),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Hero(
                tag: 'report_img_${report.reportId}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _buildImageUrl(report.imageUrl),
                    width: 85,
                    height: 85,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 85,
                      height: 85,
                      color: Colors.grey[100],
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1B5E20),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat(
                            'dd/MM/yyyy HH:mm',
                          ).format(report.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(report.status).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(report.status),
                        style: TextStyle(
                          color: _getStatusColor(report.status),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.black12),
            ],
          ),
        ),
      ),
    );
  }
}
