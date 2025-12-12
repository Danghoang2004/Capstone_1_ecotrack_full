import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:frontend_ecotrack/core/services/report_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import 'package:geolocator/geolocator.dart';

class Report_page extends StatefulWidget {
  const Report_page({super.key});

  @override
  State<Report_page> createState() => _Report_pageState();
}

class _Report_pageState extends State<Report_page> {
  // Logic và các hàm không đổi
  File? selectedImage;
  String selectedTrashType = "";
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  bool isSending = false;
  DateTime? lastSubmitTime;
  final List<String> validTrashTypes = ["Vô cơ", "Hữu cơ", "tổng hợp"];
  final ReportService reportService = ReportService(); // Khởi tạo Service

  void showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 100,
                  child: Lottie.asset('assets/lotties/animations/success.json'),
                ),
                const SizedBox(height: 7),
                const Text(
                  "Gửi báo cáo thành công!",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Cảm ơn bạn đã đóng góp cho môi trường xanh sạch 💚",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.black87),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    "Đóng",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
  // --------------------------------

  Future<void> _submitReport() async {
    final descriptionText = descriptionController.text.trim();

    if (selectedImage == null ||
        !validTrashTypes.contains(selectedTrashType) ||
        descriptionText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng điền đầy đủ thông tin hợp lệ")),
      );
      return;
    }

    if (lastSubmitTime != null &&
        DateTime.now().difference(lastSubmitTime!).inSeconds < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng chờ 30 giây trước khi gửi báo cáo tiếp theo"),
        ),
      );
      return;
    }

    if (descriptionText.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mô tả quá dài, tối đa 500 ký tự")),
      );
      return;
    }

    setState(() {
      isSending = true;
    });

    try {
      // --- [MỚI] GỌI HÀM LẤY VỊ TRÍ ---
      Position? currentPosition = await _determinePosition();

      // Nếu không lấy được vị trí (do user từ chối hoặc tắt GPS), dừng lại
      if (currentPosition == null) {
        setState(() {
          isSending = false;
        });
        return;
      }
      // --------------------------------

      bool success = await reportService.uploadReport(
        title: "Báo cáo rác thải",
        description: descriptionText,
        // --- [MỚI] TRUYỀN TỌA ĐỘ THỰC TẾ ---
        latitude: currentPosition.latitude.toString(),
        longitude: currentPosition.longitude.toString(),
        // -----------------------------------
        status: "PENDING",
        trashCategory: selectedTrashType,
        imagePath: selectedImage!.path,
      );

      if (success) {
        lastSubmitTime = DateTime.now();
        showSuccessDialog();
        // Reset form
        setState(() {
          selectedImage = null;
          descriptionController.clear();
          selectedTrashType = "";
        });
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Gửi thất bại")));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi khi gửi: $e")));
    } finally {
      if (mounted) {
        setState(() {
          isSending = false;
        });
      }
    }
  }

  // --- BUILD METHOD VÀ CÁC WIDGET CON ĐÃ TỐI ƯU ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFF8),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF2E7D32),
          elevation: 0,
          centerTitle: true,
          title: const Text(
            "Báo cáo rác thải",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {},
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
              const SizedBox(height: 20),
              _buildTrashTypeSection(),
              const SizedBox(height: 20),
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
