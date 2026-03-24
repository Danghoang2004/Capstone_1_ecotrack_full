import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:frontend_ecotrack/core/services/notification_service.dart';

class CreateNotificationScreen extends StatefulWidget {
  const CreateNotificationScreen({super.key});

  @override
  State<CreateNotificationScreen> createState() => _CreateNotificationScreenState();
}

class _CreateNotificationScreenState extends State<CreateNotificationScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  int _sendTimeOption = 0; // 0: Ngay lập tức, 1: Lên lịch
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  bool _isLoading = false;
  // 👇 Khai báo service chung của dự án
  final NotificationService _notificationService = NotificationService();
  final Color primaryGreen = const Color(0xFF5EAC24);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
                const Text("Tạo Thông Báo Mới", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildLeftColumn()),
                      const SizedBox(width: 48),
                      Expanded(flex: 4, child: _buildRightColumn()),
                    ],
                  ),
                  const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Divider(height: 1)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          foregroundColor: Colors.red.shade400,
                        ),
                        child: const Text("Hủy bỏ"),
                      ),
                      Row(
                        children: [
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                            ),
                            child: const Text("Lưu Dự Thảo", style: TextStyle(color: Colors.black87)),
                          ),
                          const SizedBox(width: 16),
                          // 🟢 NÚT GỬI NGAY ĐÃ KẾT NỐI API
                          ElevatedButton(
                            onPressed: _isLoading ? null : _handleSendNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            ),
                            child: _isLoading 
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Gửi Ngay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔵 HÀM XỬ LÝ GỬI THÔNG BÁO
  void _handleSendNotification() async {
    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập đầy đủ nội dung!'), backgroundColor: Colors.red));
      return;
    }

    String? scheduleStr;
    if (_sendTimeOption == 1) {
      if (_selectedDate == null || _selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ngày giờ lên lịch!'), backgroundColor: Colors.red));
        return;
      }
      scheduleStr = "${DateFormat('yyyy-MM-dd').format(_selectedDate!)} ${_selectedTime!.format(context)}";
    }

    setState(() => _isLoading = true);
    
    // Gọi Service chung của hệ thống
    bool success = await _notificationService.sendBroadcastNotification(
      title: title,
      message: content,
      scheduledTime: scheduleStr,
    );

    setState(() => _isLoading = false);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã gửi thông báo thành công!'), backgroundColor: Colors.green));
      Navigator.pop(context);
    } else {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gửi thất bại! Hãy kiểm tra quyền Admin.'), backgroundColor: Colors.red));
    }
  }

  Widget _buildLeftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("A. Thông tin cơ bản", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5EAC24))),
        const SizedBox(height: 24),
        const Text("Tiêu đề thông báo", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: _titleController, decoration: const InputDecoration(border: OutlineInputBorder())),
        const SizedBox(height: 24),
        const Text("Nội dung thông báo", style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        TextField(controller: _contentController, maxLines: 10, decoration: const InputDecoration(border: OutlineInputBorder())),
      ],
    );
  }

  Widget _buildRightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("B. Cấu hình gửi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5EAC24))),
        const SizedBox(height: 24),
        const Text("Thời gian gửi", style: TextStyle(color: Colors.grey)),
        Row(
          children: [
            Radio<int>(value: 0, groupValue: _sendTimeOption, activeColor: primaryGreen, onChanged: (val) => setState(() => _sendTimeOption = val!)),
            const Text("Gửi ngay lập tức"),
            const SizedBox(width: 24),
            Radio<int>(value: 1, groupValue: _sendTimeOption, activeColor: primaryGreen, onChanged: (val) => setState(() => _sendTimeOption = val!)),
            const Text("Lên lịch gửi"),
          ],
        ),
        if (_sendTimeOption == 1)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_selectedDate == null ? "Chọn ngày" : DateFormat('dd/MM/yyyy').format(_selectedDate!)),
                        const Icon(Icons.calendar_today, size: 20),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text(_selectedTime == null ? "00:00" : _selectedTime!.format(context)),
                        const Icon(Icons.access_time, size: 20),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}