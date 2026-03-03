import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';

class CheckIn_screen extends StatefulWidget {
  const CheckIn_screen({super.key});

  @override
  State<CheckIn_screen> createState() => _CheckIn_screenState();
}

class _CheckIn_screenState extends State<CheckIn_screen> {
  Uint8List? selectedImageBytes;
  final ImagePicker picker = ImagePicker();

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // Trên web, dùng HTML file input
      await _pickImageWeb();
    } else {
      // Trên mobile, dùng image_picker bình thường
      await _pickImageMobile();
    }
  }

  Future<void> _pickImageWeb() async {
    try {
      // Trên web, dùng file_picker thay vì image_picker để tránh lỗi
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.bytes != null) {
        // file_picker trả về bytes trực tiếp trên web
        final bytes = result.files.single.bytes!;

        if (mounted) {
          setState(() {
            selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      debugPrint('Lỗi khi chọn ảnh trên web: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi chọn ảnh: $e")));
      }
    }
  }

  Future<void> _pickImageMobile() async {
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();

        if (mounted) {
          setState(() {
            selectedImageBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi khi chọn ảnh: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 128, 127, 127),
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
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline, color: Colors.white),
              onPressed: () {},
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),

      body: Stack(
        children: [
          Container(color: const Color.fromARGB(255, 34, 34, 34)),
          Positioned.fill(
            child: Column(
              children: [
                const SizedBox(height: 10),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    "Quét mã QR để Check-in chiến dịch môi trường",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFF00E676), width: 4),
                  ),
                ),

                const SizedBox(height: 24),

                const Text(
                  "EcoTrack QR",
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Preview ảnh nếu đã chọn
                if (selectedImageBytes != null)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E676),
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Hiển thị ảnh từ bytes - hoạt động trên cả web và mobile
                          Image.memory(
                            selectedImageBytes!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedImageBytes = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black54,
                                padding: const EdgeInsets.all(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),

                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
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

                const SizedBox(height: 8),

                const Text(
                  "EcoTrack  •  Green Campaign  •  Community",
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),

                const SizedBox(height: 90),
              ],
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: const Color.fromARGB(255, 32, 32, 32).withOpacity(0.75),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: const _BottomItem(
                      icon: Icons.qr_code,
                      text: "Ảnh có sẵn",
                    ),
                  ),
                  const _BottomItem(icon: Icons.history, text: "Lịch sử"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    );
  }
}
