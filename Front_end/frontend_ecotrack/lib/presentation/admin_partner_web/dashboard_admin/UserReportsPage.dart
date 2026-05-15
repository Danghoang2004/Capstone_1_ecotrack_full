import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/data/utils/ImageUtils.dart';
import 'package:intl/intl.dart';

class UserReportsPage extends StatefulWidget {
  final int userId;
  final String username;

  const UserReportsPage({super.key, required this.userId, required this.username});

  @override
  State<UserReportsPage> createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  List<Report> _reports = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserReports();
  }

  Future<void> _fetchUserReports() async {
    setState(() => _isLoading = true);
    final data = await _reportService.fetchReportsByUser(widget.userId);
    if (mounted) setState(() {
      _reports = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.adminSurface,
        foregroundColor: AppColors.adminTextPrimary,
        title: Text('Báo cáo của ${widget.username}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchUserReports,
          )
        ],
      ),
      backgroundColor: AppColors.adminBackground,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _isLoading
                    ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
                    : _reports.isEmpty
                            ? const SizedBox(height: 200, child: Center(child: Text('Người dùng chưa gửi báo cáo nào.')))
                            : ConstrainedBox(
                                // allow card to size to content, but cap height so it doesn't fill whole screen
                                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.72),
                                child: ListView.separated(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  shrinkWrap: true,
                                  physics: const AlwaysScrollableScrollPhysics(),
                                  itemBuilder: (ctx, idx) {
                                final r = _reports[idx];
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(10),
                                    leading: r.imageUrl.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              ImageUtils.buildUrl(r.imageUrl),
                                              width: 56,
                                              height: 56,
                                              fit: BoxFit.cover,
                                              loadingBuilder: (ctx, child, progress) {
                                                if (progress == null) return child;
                                                return SizedBox(
                                                  width: 56,
                                                  height: 56,
                                                  child: Center(
                                                    child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null),
                                                  ),
                                                );
                                              },
                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                                            ),
                                          )
                                        : const Icon(Icons.image_not_supported),
                                    title: Text(r.title),
                                    subtitle: Text('${_statusLabel(r.status)} • ${DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt)}'),
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) {
                                          final maxW = MediaQuery.of(ctx).size.width * 0.7;
                                          final maxH = MediaQuery.of(ctx).size.height * 0.7;
                                          return AlertDialog(
                                            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                            title: Text(r.title),
                                            content: ConstrainedBox(
                                              constraints: BoxConstraints(maxWidth: maxW, maxHeight: maxH),
                                              child: SingleChildScrollView(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    if (r.imageUrl.isNotEmpty)
                                                      GestureDetector(
                                                        onTap: () {
                                                          showDialog(
                                                            context: context,
                                                            builder: (_) => Dialog(
                                                              insetPadding: const EdgeInsets.all(16),
                                                              child: InteractiveViewer(
                                                                panEnabled: true,
                                                                minScale: 1,
                                                                maxScale: 4,
                                                                child: Image.network(
                                                                  ImageUtils.buildUrl(r.imageUrl),
                                                                  fit: BoxFit.contain,
                                                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                                                                ),
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                        child: ClipRRect(
                                                          borderRadius: BorderRadius.circular(8),
                                                          child: SizedBox(
                                                            width: double.infinity,
                                                            height: 220,
                                                            child: Image.network(
                                                              ImageUtils.buildUrl(r.imageUrl),
                                                              fit: BoxFit.cover,
                                                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 48),
                                                              loadingBuilder: (c, child, progress) {
                                                                if (progress == null) return child;
                                                                return SizedBox(
                                                                  width: double.infinity,
                                                                  height: 220,
                                                                  child: Center(
                                                                    child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null),
                                                                  ),
                                                                );
                                                              },
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(height: 12),
                                                    Text(
                                                      r.description,
                                                      style: const TextStyle(fontSize: 14, height: 1.4),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text('Trạng thái: ${_statusLabel(r.status)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                    const SizedBox(height: 6),
                                                    Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(r.createdAt)}'),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                );
                              },
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemCount: _reports.length,
                            ),
                          ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return 'Chờ xử lý';
      case 'VERIFIED':
        return 'Đã xác minh';
      case 'CLEANED':
        return 'Đã dọn dẹp';
      case 'REJECTED':
        return 'Đã từ chối';
      default:
        return status;
    }
  }
}
