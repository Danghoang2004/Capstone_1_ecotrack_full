import 'package:flutter/material.dart';
import 'notification_controller.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() =>
      _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  // Controllers
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  // State variables
  String _selectedType = 'Hệ thống';
  String _selectedTarget = 'Tất cả người dùng';
  int _sendTimeOption = 0; // 0: Ngay lập tức, 1: Lên lịch
  bool _addLink = false;
  bool _sendEmail = true;

  // Màu chủ đạo của EcoTrack
  bool _isLoading = false;
  final NotificationController _controller = NotificationController();
  final Color primaryGreen = const Color(0xFF5EAC24);

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Kế thừa màu nền của Layout tổng
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER ---
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context), // Nút quay lại
                ),
                const SizedBox(width: 8),
                const Text(
                  "Tạo Thông Báo Mới",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- MAIN FORM CARD ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- CỘT TRÁI: THÔNG TIN CƠ BẢN ---
                        Expanded(flex: 5, child: _buildLeftColumn()),
                        const SizedBox(width: 48), // Khoảng cách giữa 2 cột
                        // --- CỘT PHẢI: CẤU HÌNH GỬI ---
                        Expanded(flex: 4, child: _buildRightColumn()),
                      ],
                    ),

                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Divider(height: 1),
                    ),

                    // --- FOOTER: BUTTONS ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Nút Hủy
                        OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            foregroundColor: Colors.red.shade400,
                            side: BorderSide(color: Colors.red.shade200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text("Hủy bỏ"),
                        ),

                        // Cụm nút Lưu Dự Thảo & Gửi Ngay
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () {
                                // TODO: Xử lý lưu dự thảo sau
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey.shade200,
                                foregroundColor: Colors.black87,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text("Lưu Dự Thảo"),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      String title = _titleController.text
                                          .trim();
                                      String content = _contentController.text
                                          .trim();

                                      // 1. Kiểm tra không được để trống
                                      if (title.isEmpty || content.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Vui lòng nhập đầy đủ Tiêu đề và Nội dung!',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                        return;
                                      }

                                      // 2. Bật trạng thái quay mòng mòng (Loading)
                                      setState(() => _isLoading = true);

                                      // 3. Gọi hàm gửi API
                                      bool success = await _controller
                                          .sendNotification(
                                            context: context,
                                            title: title,
                                            message: content,
                                          );

                                      // 4. Tắt loading
                                      setState(() => _isLoading = false);

                                      // 5. Hiển thị thông báo thành công / thất bại
                                      if (success) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Đã gửi thông báo thành công!',
                                              ),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          Navigator.pop(
                                            context,
                                          ); // Đóng form quay về trang trước
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Lỗi gửi thông báo!',
                                              ),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      "Gửi Ngay",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CÁC HÀM XÂY DỰNG GIAO DIỆN CON =================

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("A", "Thông tin cơ bản"),
        const SizedBox(height: 24),

        _buildLabel("Tiêu đề thông báo"),
        TextField(
          controller: _titleController,
          decoration: _inputDecoration("VD: Hệ thống bảo trì định kỳ..."),
        ),
        const SizedBox(height: 24),

        _buildLabel("Nội dung thông báo"),
        // Khung giả lập Rich Text Editor
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Column(
            children: [
              // Thanh công cụ ảo
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade300),
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.format_bold, size: 20),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_italic, size: 20),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                    ),
                    IconButton(
                      icon: const Icon(Icons.format_underline, size: 20),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                    ),
                    Container(
                      width: 1,
                      height: 20,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.link, size: 20),
                      onPressed: () {},
                      color: Colors.grey.shade700,
                    ),
                  ],
                ),
              ),
              // Ô nhập nội dung
              TextField(
                controller: _contentController,
                maxLines: 10,
                decoration: const InputDecoration(
                  hintText: "Nhập nội dung chi tiết...",
                  hintStyle: TextStyle(color: Colors.black38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("B", "Cấu hình gửi"),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Loại thông báo"),
                  _buildDropdown(
                    ['Hệ thống', 'Khuyến mãi', 'Cập nhật', 'Sự kiện'],
                    _selectedType,
                    (val) {
                      setState(() => _selectedType = val!);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("Đối tượng nhận"),
                  _buildDropdown(
                    ['Tất cả người dùng', 'Người dùng mới'],
                    _selectedTarget,
                    (val) {
                      setState(() => _selectedTarget = val!);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        _buildLabel("Thời gian gửi"),
        Row(
          children: [
            Radio<int>(
              value: 0,
              groupValue: _sendTimeOption,
              activeColor: primaryGreen,
              onChanged: (val) => setState(() => _sendTimeOption = val!),
            ),
            const Text("Gửi ngay lập tức"),
            const SizedBox(width: 24),
            Radio<int>(
              value: 1,
              groupValue: _sendTimeOption,
              activeColor: primaryGreen,
              onChanged: (val) => setState(() => _sendTimeOption = val!),
            ),
            const Text("Lên lịch gửi"),
          ],
        ),

        // Hiện ô chọn ngày giờ nếu chọn "Lên lịch gửi"
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _sendTimeOption == 1 ? 60 : 0,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: _buildDateTimePicker(
                    Icons.calendar_today,
                    "Chọn ngày",
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildDateTimePicker(Icons.access_time, "00:00"),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),
        _buildSectionTitle("C", "Tùy chọn nâng cao"),
        const SizedBox(height: 16),

        Row(
          children: [
            Checkbox(
              value: _addLink,
              activeColor: primaryGreen,
              onChanged: (val) => setState(() => _addLink = val!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Text("Thêm liên kết (Link / Button)"),
          ],
        ),
        Row(
          children: [
            Switch(
              value: _sendEmail,
              activeColor: primaryGreen,
              onChanged: (val) => setState(() => _sendEmail = val),
            ),
            const Text("Gửi email thông báo song song"),
          ],
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSectionTitle(String letter, String title) {
    return Row(
      children: [
        Text(
          "$letter.",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: primaryGreen,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black38),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: primaryGreen, width: 1.5),
      ),
    );
  }

  Widget _buildDropdown(
    List<String> items,
    String value,
    Function(String?) onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          items: items.map((String item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildDateTimePicker(IconData icon, String text) {
    return InkWell(
      onTap: () {}, // Hiện DatePicker hoặc TimePicker
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(text, style: TextStyle(color: Colors.grey.shade600)),
            Icon(icon, size: 20, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }
}
