import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:frontend_ecotrack/core/services/report_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';
import 'ListReport_page.dart';

class Report_page extends StatefulWidget {
  const Report_page({super.key});

  @override
  State<Report_page> createState() => _Report_pageState();
}

class _Report_pageState extends State<Report_page> {
  // Logic và các hàm không đổi
  File? selectedImage;
  String selectedTrashType = "rác thải"; // Gán mặc định tại đây
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController titleController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  bool isSending = false;
  DateTime? lastSubmitTime;
  final List<String> validTrashTypes = ["Vô cơ", "Hữu cơ", "tổng hợp"];
  final ReportService reportService = ReportService(); // Khởi tạo Service

  String _getAiDecisionVietnamese(String? aiDecision) {
    switch ((aiDecision ?? '').toUpperCase()) {
      case 'WASTE_DETECTED':
        return 'Phát hiện rác';
      case 'NOT_WASTE':
        return 'Không phải rác';
      case 'UNCERTAIN':
        return 'Chưa chắc chắn';
      case 'REQUEST_REUPLOAD':
        return 'Yêu cầu chụp lại';
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Thông báo", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text(
          message, // Đây sẽ là tin nhắn "Vui lòng chờ X phút" từ Backend
          style: const TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "ĐÃ HIỂU",
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // --- GIAO DIỆN TICKET BÁO CÁO THÀNH CÔNG ---
  void _showReportSuccessTicket(Map<String, dynamic> data) {
    final String reportStatus =
        (data['report_status'] ?? data['status'] ?? 'PENDING').toString();
    final Map<String, dynamic> aiResult = data['ai_result'] is Map
        ? Map<String, dynamic>.from(data['ai_result'] as Map)
        : <String, dynamic>{};
    final String pollutionLevel = (aiResult['pollution_level'] ?? 'UNCONFIRMED')
        .toString();
    final String pollutionLevelVi = _getPollutionLevelVietnamese(
      pollutionLevel,
    );
    final String aiDecisionVi = _getAiDecisionVietnamese(
      (aiResult['ai_decision'] ?? 'NOT_WASTE').toString(),
    );
    final String severityText =
        (aiResult['severity_description'] ?? data['message'] ?? '').toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animation Lottie Success
              SizedBox(
                height: 120,
                child: Lottie.asset(
                  'assets/lotties/animations/success.json',
                  repeat: false,
                ),
              ),

              Text(
                reportStatus == 'REQUEST_REUPLOAD'
                    ? 'Ảnh cần chụp lại'
                    : 'Gửi báo cáo thành công!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: reportStatus == 'REQUEST_REUPLOAD'
                      ? Colors.orange[700]
                      : Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data['message'] ?? "Cảm ơn bạn đã đóng góp vì môi trường!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),

              if (aiResult.isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4FBF8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Kết luận AI: $aiDecisionVi",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text("Mức ô nhiễm: $pollutionLevelVi"),
                      Text(
                        "Điểm ô nhiễm: ${(aiResult['severity_score'] ?? 'N/A').toString()}",
                      ),
                      const SizedBox(height: 6),
                      Text(
                        severityText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Widget hiển thị điểm (Nếu AI xác thực ngay và tặng điểm)
              if (data['points'] > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.orangeAccent.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.stars, color: Colors.orange, size: 24),
                      const SizedBox(width: 8),
                      Text(
                        "+${data['points']} Điểm xanh",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),
              const Divider(height: 1),
              const SizedBox(height: 15),

              // Chi tiết giao dịch
              _buildTicketRow(
                "Trạng thái",
                reportStatus == "AI_VERIFIED"
                    ? "Đã xác thực bởi AI"
                    : reportStatus == "NEED_REVIEW"
                    ? "Cần kiểm duyệt"
                    : reportStatus == "REQUEST_REUPLOAD"
                    ? "Cần chụp lại"
                    : "Đang chờ duyệt",
              ),
              _buildTicketRow("Mã báo cáo", data['transactionCode'] ?? "N/A"),
              _buildTicketRow("Thời gian", _formatServerTime(data['time'])),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "TIẾP TỤC SỐNG XANH",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  // Hàm hỗ trợ vẽ dòng thông tin
  Widget _buildTicketRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Hàm format thời gian từ server
  String _formatServerTime(String? timeStr) {
    if (timeStr == null) return "Vừa xong";
    try {
      DateTime dt = DateTime.parse(timeStr);
      return "${dt.hour}:${dt.minute} - ${dt.day}/${dt.month}/${dt.year}";
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _pickImage() async {
    try {
      // Cho phép chọn từ Gallery hoặc Camera
      final choice = await showModalBottomSheet<ImageSource>(
        context: context,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera),
              title: const Text('Chụp ảnh'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Chọn từ thư viện'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      );

      if (choice == null) return; // Người dùng hủy bỏ

      final XFile? image = await picker.pickImage(source: choice);
      if (image != null) {
        final file = File(image.path);

        final fileSize = await file.length();
        // Kiểm tra kích thước file > 5MB
        if (fileSize > 5 * 1024 * 1024) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ảnh quá lớn, tối đa 5MB")),
          );
          return;
        }

        setState(() {
          selectedImage = file;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi chọn ảnh: $e")));
    }
  }

  // --- [MỚI] HÀM LẤY VỊ TRÍ GPS ---
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Kiểm tra GPS có bật không
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bật định vị (GPS) trên điện thoại'),
        ),
      );
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối')),
        );
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Quyền vị trí bị từ chối vĩnh viễn. Hãy vào Cài đặt để cấp quyền.',
          ),
        ),
      );
      return null;
    }

    // Lấy vị trí hiện tại (High accuracy để chính xác nhất)
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  void dispose() {
    descriptionController.dispose();
    titleController.dispose();
    super.dispose();
  }
  // --------------------------------

  Future<void> _submitReport() async {
    final descriptionText = descriptionController.text.trim();
    final titleText = titleController.text.trim();

    if (titleText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập tiêu đề báo cáo")),
      );
      return;
    }

    if (selectedImage == null || descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chụp ảnh và nhập mô tả")),
      );
      return;
    }

    setState(() => isSending = true);

    try {
      Position? currentPosition = await _determinePosition();
      if (currentPosition == null) {
        setState(() => isSending = false);
        return;
      }

      // GỌI SERVICE VÀ NHẬN DATA
      final resultData = await reportService.uploadReport(
        title: titleText,
        description: descriptionText,
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        status: "PENDING",
        trashCategory: selectedTrashType,
        imagePath: selectedImage!.path,
      );
      if (resultData != null) {
        // KIỂM TRA SUCCESS TỪ BACKEND TRẢ VỀ
        if (resultData['success'] == true ||
            resultData['status'] == "PENDING") {
          // 1. Trường hợp thành công hoặc đang chờ duyệt
          _showReportSuccessTicket(resultData);
          setState(() {
            selectedImage = null;
            descriptionController.clear();
            titleController.clear();
          });
        } else {
          // 2. [QUAN TRỌNG] Trường hợp lỗi Business (Cooldown, Limit, AI reject)
          // Hiển thị message lỗi ở giữa màn hình
          _showErrorDialog(resultData['message'] ?? "Gửi báo cáo thất bại");
        }
      } else {
        _showErrorDialog("Lỗi hệ thống, vui lòng thử lại sau");
      }
    } catch (e) {
      _showErrorDialog("Lỗi: $e");
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  // --- BUILD METHOD VÀ CÁC WIDGET CON ĐÃ TỐI ƯU ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0,
          shadowColor: Colors.transparent,
          forceMaterialTransparency: true,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text(
            "Báo cáo rác thải",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.black87),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ListReportPage(),
                  ),
                );
              },
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePickerSection(),
              const SizedBox(height: 12),
              _buildTitleSection(),
              const SizedBox(height: 20),
              // _buildTrashTypeSection() đã được lược bỏ theo yêu cầu
              _buildDescriptionSection(),
              const SizedBox(height: 15),
              _buildSubmitButton(),
              const SizedBox(height: 15),
              _buildFooter(),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePickerSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.camera_alt_outlined),
              SizedBox(width: 10),
              Text(
                "Chụp ảnh rác thải",
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GestureDetector(
              onTap: _pickImage,
              child: DottedBorder(
                color: Colors.grey,
                strokeWidth: 1.2,
                dashPattern: const [6, 4],
                borderType: BorderType.RRect,
                radius: const Radius.circular(8),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.camera_alt,
                              size: 40,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Nhấn để chụp ảnh\nhoặc chọn từ thư viện',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget này vẫn giữ lại trong code nhưng không gọi trong build để tránh lỗi compile
  Widget _buildTrashTypeSection() {
    return Container(
      height: 120,
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.delete_outline),
              SizedBox(width: 10),
              Text(
                "Loại rác thải",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(children: validTrashTypes.map(_buildTrashTypeButton).toList()),
        ],
      ),
    );
  }

  Widget _buildTrashTypeButton(String label) {
    final isSelected = selectedTrashType == label;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green[200] : Colors.white,
          side: BorderSide(color: isSelected ? Colors.green : Colors.grey),
          minimumSize: const Size(20, 30),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () {
          setState(() {
            selectedTrashType = label;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.description),
              SizedBox(width: 10),
              Text(
                "Mô tả chi tiết",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            "Mô tả tình trạng rác thải",
            style: TextStyle(fontSize: 14, color: Colors.black87),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextField(
              controller: descriptionController,
              maxLines: 4,
              maxLength: 500,
              style: const TextStyle(fontSize: 14, color: Colors.black),
              decoration: const InputDecoration(
                hintText:
                    "Ví dụ: Nhiều chai nhựa và túi nilon bị vứt bừa bãi ở góc đường...",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                helperText: "(tối đa 500 ký tự)",
                helperStyle: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.subject),
              SizedBox(width: 10),
              Text(
                "Tiêu đề báo cáo",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              hintText: 'Nhập tiêu đề, ví dụ: Túi nhựa vứt bừa bãi',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: isSending ? null : _submitReport,
      icon: isSending
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.file_upload_outlined, color: Colors.white),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
        backgroundColor: isSending
            ? Colors.grey
            : const Color.fromARGB(255, 94, 185, 103),
        shadowColor: const Color.fromARGB(255, 111, 110, 109),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      label: Text(
        isSending ? "Đang gửi..." : "Gửi báo cáo",
        style: const TextStyle(
          color: Color.fromARGB(255, 243, 243, 243),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 223, 236, 213),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.all(15.0),
        child: Text(
          "💚 Mỗi báo cáo của bạn giúp cộng đồng có môi trường sạch hơn. Bạn sẽ nhận được điểm thưởng sau khi báo cáo được xác nhận 💚",
          style: TextStyle(
            fontSize: 11,
            color: Color.fromARGB(255, 27, 134, 30),
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
