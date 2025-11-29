import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';

class CheckIn_screen extends StatefulWidget {
  const CheckIn_screen({super.key});

  @override
  State<CheckIn_screen> createState() => _CheckIn_screenState();
}

class _CheckIn_screenState extends State<CheckIn_screen> {
  // Biến để kiểm soát việc quét, tránh quét liên tục
  bool _scanCompleted = false;
  final MobileScannerController _controller = MobileScannerController();
  late ApiClient _apiClient;

  @override
  void initState() {
    super.initState();
    // Khởi tạo ApiClient
    const storage = FlutterSecureStorage();
    _apiClient = ApiClient(storage: storage);
  }

  // Hàm hiển thị thông báo kết quả check-in
  void _showResultDialog(String title, String message, Color color) {
    showDialog(
      context: context,
      barrierDismissible:
          false, // Không cho phép dismiss bằng cách chạm ra ngoài
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
          actions: <Widget>[
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Color(0xFF2E7D32)),
              ),
              onPressed: () {
                // Đóng dialog
                Navigator.of(dialogContext).pop();
                // Sau khi đóng, bật lại camera và cho phép quét lại
                if (mounted) {
                  setState(() {
                    _scanCompleted = false;
                    _controller.start(); // Bắt đầu lại camera
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Hàm xử lý logic gọi API check-in
  void _performCheckin(Map<String, dynamic> qrData) async {
    // Tạm dừng camera ngay lập tức sau khi bắt được mã
    _controller.stop();

    // Đảm bảo chỉ gọi API một lần
    if (_scanCompleted) return;
    _scanCompleted = true;

    // Hiển thị thông báo đang xử lý
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đang xử lý Check-in..."),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.blueGrey,
      ),
    );

    try {
      final response = await _apiClient.post(
        '/api/user/campaigns/checkin',
        qrData,
      );

      final data = _apiClient.decodeUtf8Json(response);

      if (response.statusCode == 200) {
        _showResultDialog(
          "Thành công",
          data['message'] ?? "Check-in chiến dịch thành công!",
          Colors.green,
        );
      } else {
        // Backend trả về lỗi (ví dụ: đã check-in, ngoài thời gian, lỗi xác thực)
        _showResultDialog(
          "Thất bại",
          data['message'] ?? "Check-in thất bại. Vui lòng thử lại.",
          Colors.red,
        );
      }
    } catch (e) {
      _showResultDialog(
        "Lỗi kết nối",
        "Không thể kết nối đến máy chủ: $e",
        Colors.red,
      );
    }
  }

  // Hàm xử lý dữ liệu QR code
  void _handleScan(BarcodeCapture capture) {
    if (_scanCompleted || !mounted) return;

    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;

    if (rawValue == null || rawValue.isEmpty) return;

    try {
      // Phân tích cú pháp chuỗi JSON từ QR code
      final Map<String, dynamic> qrData = jsonDecode(rawValue);

      final String action = qrData['action'] as String? ?? '';
      final int? campaignIdInt = qrData['campaignId'] as int?;

      if (action == "CHECKIN" && campaignIdInt != null) {
        // Chuyển đổi ID từ int sang Long (backend)
        _performCheckin({"action": action, "campaignId": campaignIdInt});
      } else {
        _showResultDialog(
          "Mã QR không hợp lệ",
          "Mã QR không chứa thông tin chiến dịch hợp lệ (thiếu action hoặc campaignId).",
          Colors.orange,
        );
      }
    } catch (e) {
      _showResultDialog(
        "Lỗi đọc mã",
        "Dữ liệu mã QR không phải là định dạng JSON hợp lệ: $e",
        Colors.orange,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Chiều rộng và chiều cao của vùng quét
    final scanAreaSize = MediaQuery.of(context).size.width * 0.7;
    final scanAreaSizeh = MediaQuery.of(context).size.height * 0.5;
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 34, 34, 34),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          title: const Text(
            "Quét Mã QR",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),

      body: Stack(
        children: [
          // --- Camera ---
          MobileScanner(
            controller: _controller,
            onDetect: _handleScan,
            fit: BoxFit.cover,
          ),

          // --- Overlay + khung quét ---
          LayoutBuilder(
            builder: (context, constraints) {
              final double scanWidth = constraints.maxWidth * 0.75;
              final double scanHeight = constraints.maxHeight * 0.38;

              final double left = (constraints.maxWidth - scanWidth) / 2;
              final double top = (constraints.maxHeight - scanHeight) / 2.5;

              return Stack(
                children: [
                  // Lớp mờ
                  ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.black.withOpacity(0.55),
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

                        // Vùng trong suốt
                        Positioned(
                          left: left,
                          top: top,
                          child: Container(
                            width: scanWidth,
                            height: scanHeight,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viền khung
                  Positioned(
                    left: left,
                    top: top,
                    child: Container(
                      width: scanWidth,
                      height: scanHeight,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00E676),
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  // Text hướng dẫn
                  Positioned(
                    top: top - 60,
                    left: 0,
                    right: 0,
                    child: const Text(
                      "Đưa mã QR của chiến dịch vào khung để check-in",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // Text dưới khung
                  Positioned(
                    top: top + scanHeight + 20,
                    left: 0,
                    right: 0,
                    child: const Text(
                      "EcoTrack QR Scanner",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // --- ICON + TEXT dưới cùng ---
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Column(
              children: const [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.eco, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Icon(Icons.public, color: Colors.white70, size: 22),
                    SizedBox(width: 10),
                    Icon(
                      Icons.volunteer_activism,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  "EcoTrack • Green Campaign • Cộng đồng",
                  style: TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),

          // --- Thanh nút dưới ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color.fromARGB(255, 32, 32, 32).withOpacity(0.9),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BottomItem(icon: Icons.image, text: "Ảnh có sẵn"),
                  _BottomItem(icon: Icons.history, text: "Lịch sử"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _BottomItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _BottomItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 22),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
      ],
    );
  }
}
