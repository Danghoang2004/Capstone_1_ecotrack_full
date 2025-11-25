import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:frontend_ecotrack/core/services/report_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';

class Report_page extends StatefulWidget {
  const Report_page({super.key});

  @override
  State<Report_page> createState() => _Report_pageState();
}

class _Report_pageState extends State<Report_page> {
  File? selectedImage;
  String selectedTrashType = "";
  final TextEditingController descriptionController = TextEditingController();
  final ImagePicker picker = ImagePicker();
  bool isSending = false;

  DateTime? lastSubmitTime;

  final List<String> validTrashTypes = ["Vô cơ", "Hữu cơ", "tổng hợp"];

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
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final file = File(image.path);

        final fileSize = await file.length();
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
      final reportService = ReportService();

      bool success = await reportService.uploadReport(
        title: "Báo cáo rác thải",
        description: descriptionText,
        latitude: "10.762622",
        longitude: "106.660172",
        status: "PENDING",
        trashCategory: selectedTrashType,
        imagePath: selectedImage!.path,
      );

      if (success) {
        lastSubmitTime = DateTime.now();

        showSuccessDialog();

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
      setState(() {
        isSending = false;
      });
    }
  }

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
          padding: const EdgeInsets.all(8.0),
          child: Column(
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
      width: 300,
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
          GestureDetector(
            onTap: _pickImage,
            child: DottedBorder(
              color: Colors.grey,
              strokeWidth: 1.2,
              dashPattern: const [6, 4],
              borderType: BorderType.RRect,
              radius: const Radius.circular(8),
              child: Container(
                width: double.infinity,
                height: 120,
                color: Colors.grey[100],
                child: selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Nhấn để chụp ảnh\nhoặc chọn từ thư viện',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : Image.file(selectedImage!, fit: BoxFit.cover),
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
      width: 300,
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
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: isSelected ? Colors.green[200] : Colors.white,
          side: BorderSide(color: isSelected ? Colors.green : Colors.grey),
          minimumSize: const Size(20, 30),
        ),
        onPressed: () {
          setState(() {
            selectedTrashType = label;
          });
        },
        child: Text(
          label,
          style: const TextStyle(fontSize: 9, color: Colors.black),
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
              style: const TextStyle(fontSize: 14, color: Colors.black),
              decoration: const InputDecoration(
                hintText:
                    "Ví dụ: Nhiều chai nhựa và túi nilon bị vứt bừa bãi ở góc đường...( tối đa 500 ký tự )",
                hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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
        minimumSize: const Size(double.infinity, 40),
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
      width: 300,
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
