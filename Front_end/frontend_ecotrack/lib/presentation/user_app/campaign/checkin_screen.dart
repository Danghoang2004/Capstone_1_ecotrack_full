import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';

class CheckIn_screenreal extends StatefulWidget {
  const CheckIn_screenreal({super.key});

  @override
  State<CheckIn_screenreal> createState() => _CheckIn_screenrealState();
}

class _CheckIn_screenrealState extends State<CheckIn_screenreal> {
  bool _scanCompleted = false;
  final MobileScannerController _controller = MobileScannerController();
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    _apiClient = ApiClient(storage: storage);
  }

  // --- 1. GIAO DIỆN LOG THÀNH CÔNG (SUCCESS TICKET) ---
  void _showSuccessTicket(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Success nổi bật
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF2E7D32),
                  size: 60,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Check-in Thành Công!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Bạn đã tích lũy thêm điểm xanh",
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Widget hiển thị điểm thưởng
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Colors.orange, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      "+${data['points']} Điểm",
                      style: const TextStyle(
                        fontSize: 24,
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 16),

              // Thông tin chi tiết từ Backend
              _buildTicketRow("Người thực hiện", data['userName'] ?? "N/A"),
              _buildTicketRow("Chiến dịch", data['campaignTitle'] ?? "N/A"),
              _buildTicketRow(
                "Thời gian",
                _formatDateTime(data['checkinTime']),
              ),
              _buildTicketRow("Mã giao dịch", data['transactionId'] ?? "N/A"),

              const SizedBox(height: 24),

              // Nút xác nhận để đóng và tiếp tục
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (mounted) {
                      setState(() {
                        _scanCompleted = false;
                        _controller.start(); // Bật lại camera
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "TUYỆT VỜI",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper cho Ticket Row
  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hàm hiển thị lỗi/thông báo thường
  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(
                color == Colors.green ? Icons.check_circle : Icons.error,
                color: color,
              ),
              const SizedBox(width: 10),
              Text(title),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text(
                'ĐÓNG',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) {
                  setState(() {
                    _scanCompleted = false;
                    _controller.start();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // --- 2. LOGIC XỬ LÝ API ---
  void _performCheckin(Map<String, dynamic> qrData) async {
    _controller.stop(); // Dừng camera ngay khi bắt được mã
    if (_scanCompleted) return;
    _scanCompleted = true;

    try {
      final response = await _apiClient.post(
        '/api/user/campaigns/checkin',
        qrData,
      );
      final data = _apiClient.decodeUtf8Json(response);

      if (response.statusCode == 200) {
        // HIỂN THỊ LOG THÀNH CÔNG VỚI DỮ LIỆU THẬT
        _showSuccessTicket(data['data']);
      } else {
        _showResultDialog(
          "Thất bại",
          data['message'] ?? "Vui lòng thử lại",
          Colors.red,
        );
      }
    } catch (e) {
      _showResultDialog("Lỗi kết nối", "Không thể kết nối máy chủ", Colors.red);
    }
  }

  void _handleScan(BarcodeCapture capture) {
    if (_scanCompleted || !mounted) return;
    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return;

    try {
      final Map<String, dynamic> qrData = jsonDecode(rawValue);
      final String action = qrData['action'] as String? ?? '';
      final int? campaignIdInt = qrData['campaignId'] as int?;

      if (action == "CHECKIN" && campaignIdInt != null) {
        _performCheckin({"action": action, "campaignId": campaignIdInt});
      } else {
        _showResultDialog(
          "Mã không hợp lệ",
          "Mã QR không đúng định dạng chiến dịch",
          Colors.orange,
        );
      }
    } catch (e) {
      _showResultDialog("Lỗi đọc mã", "Dữ liệu QR không hợp lệ", Colors.orange);
    }
  }

  String _formatDateTime(String? isoString) {
    if (isoString == null) return "N/A";
    try {
      DateTime dt = DateTime.parse(isoString);
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} - ${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: true,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          "Quét Mã QR",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleScan,
            fit: BoxFit.cover,
          ),

          // Khung quét QR Overlay
          _buildScannerOverlay(context),

          // Footer Info
          Positioned(
            bottom: 110,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: Colors.white70, size: 20),
                    SizedBox(width: 15),
                    Icon(
                      Icons.volunteer_activism,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "EcoTrack • Cộng đồng sống xanh",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double scanWidth = constraints.maxWidth * 0.75;
        final double scanHeight = constraints.maxHeight * 0.35;
        final double left = (constraints.maxWidth - scanWidth) / 2;
        final double top = (constraints.maxHeight - scanHeight) / 2.5;

        return Stack(
          children: [
            // Lớp mờ xung quanh
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanWidth,
                      height: scanHeight,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Viền khung quét
            Positioned(
              left: left,
              top: top,
              child: Container(
                width: scanWidth,
                height: scanHeight,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF00E676), width: 3),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Positioned(
              top: top - 40,
              left: 0,
              right: 0,
              child: const Text(
                "Đưa mã QR vào khung để check-in",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
