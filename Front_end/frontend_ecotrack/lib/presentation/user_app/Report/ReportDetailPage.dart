import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // [MỚI]
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:intl/intl.dart';

class ReportDetailPage extends StatelessWidget {
  final Report report;

  const ReportDetailPage({super.key, required this.report});

  String _getAiDecisionVietnamese(String? aiDecision) {
    switch ((aiDecision ?? '').toUpperCase()) {
      case 'WASTE_DETECTED':
        return 'Phát hiện rác';
      case 'NOT_WASTE':
        return 'Không phải rác';
      case 'UNCERTAIN':
        return 'Chưa chắc chắn';
      default:
        return (aiDecision ?? 'Chưa xác định').toString();
    }
  }

  String _getPollutionLevelVietnamese(String? pollutionLevel) {
    switch ((pollutionLevel ?? '').toUpperCase()) {
      case 'LOW':
        return 'Thấp';
      case 'MEDIUM':
        return 'Trung bình';
      case 'HIGH':
        return 'Cao';
      case 'CRITICAL':
        return 'Nghiêm trọng';
      case 'UNCONFIRMED':
        return 'Chưa xác nhận';
      default:
        return (pollutionLevel ?? 'Chưa xác định').toString();
    }
  }

  // [MỚI] Hàm xử lý URL ảnh
  String _buildImageUrl(String? path) {
    if (path == null || path.isEmpty) return "";
    if (path.startsWith("http")) return path;

    final String baseUrl = dotenv.env['API_BASE_URL'] ?? "http://10.0.2.2:8080";
    return "$baseUrl$path";
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'VERIFIED':
        return Colors.blue;
      case 'CLEANED':
        return Colors.green;
      case 'REJECTED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // [MỚI] Gọi hàm xử lý URL
    String displayImageUrl = _buildImageUrl(report.imageUrl);
    Map<String, dynamic>? aiData;
    if (report.aiAnalysisJson != null && report.aiAnalysisJson!.isNotEmpty) {
      try {
        aiData = jsonDecode(report.aiAnalysisJson!) as Map<String, dynamic>;
      } catch (_) {
        aiData = null;
      }
    }
    final Map<String, dynamic> analysisData = aiData ?? <String, dynamic>{};

    return Scaffold(
      // Scaffold tự động có nút Back trên AppBar nếu dùng Navigator.push
      // Nhưng ta có thể custom lại nếu muốn
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF2E7D32),
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(
                displayImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            // Nút back mặc định sẽ hiện ở đây, màu trắng
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge trạng thái
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(report.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          report.status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(report.createdAt),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(
                        Icons.category_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Loại: ${report.category}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(),

                  const Text(
                    "Mô tả chi tiết",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.description.isEmpty
                        ? "Không có mô tả."
                        : report.description,
                    style: const TextStyle(
                      fontSize: 16,
                      height: 1.5,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),

                  if (report.aiVerified != null) ...[
                    const Text(
                      "Kết quả phân tích AI",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.purple.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAIRow(
                            "Xác nhận rác thải:",
                            report.aiVerified! ? "Đúng" : "Không phải rác",
                          ),
                          const SizedBox(height: 8),
                          _buildAIRow(
                            "Điểm AI tổng hợp:",
                            "${(report.aiConfidence! * 100).toStringAsFixed(1)}%",
                          ),
                          if (report.aiPollutionLevel != null) ...[
                            const SizedBox(height: 8),
                            _buildAIRow(
                              "Mức ô nhiễm:",
                              _getPollutionLevelVietnamese(
                                report.aiPollutionLevel,
                              ),
                            ),
                          ],
                          if (report.aiSeverityScore != null) ...[
                            const SizedBox(height: 8),
                            _buildAIRow(
                              "Điểm ô nhiễm:",
                              "${report.aiSeverityScore}/100",
                            ),
                          ],
                          if (report.aiWasteType != null) ...[
                            const SizedBox(height: 8),
                            _buildAIRow("Loại rác AI:", report.aiWasteType!),
                          ],
                          if (report.aiNeedManualReview == true) ...[
                            const SizedBox(height: 8),
                            _buildAIRow("Trạng thái AI:", "Cần kiểm duyệt"),
                          ],
                          if (report.aiFalsePositiveReason != null &&
                              report.aiFalsePositiveReason!.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: Colors.orange.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.warning_amber,
                                    color: Colors.orange,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      report.aiFalsePositiveReason!,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (aiData != null) ...[
                    const Text(
                      "Chi tiết phân tích",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blueGrey.withOpacity(0.12),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAIRow(
                            "Kết luận AI:",
                            _getAiDecisionVietnamese(
                              (analysisData['ai_decision'] ??
                                      report.aiDecision ??
                                      'N/A')
                                  .toString(),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildAIRow(
                            "Ngữ cảnh rác:",
                            (analysisData['waste_context_score'] ??
                                    report.aiWasteContextScore ??
                                    0)
                                .toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildAIRow(
                            "Diện tích rác:",
                            (analysisData['waste_area_ratio'] ??
                                    report.aiWasteAreaRatio ??
                                    0)
                                .toString(),
                          ),
                          const SizedBox(height: 8),
                          _buildAIRow(
                            "Số lượng vật thể:",
                            (analysisData['object_count'] ??
                                    report.aiObjectCount ??
                                    0)
                                .toString(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Text(
                    "Vị trí",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Colors.red),
                      const SizedBox(width: 8),
                      Text("${report.latitude}, ${report.longitude}"),
                    ],
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
