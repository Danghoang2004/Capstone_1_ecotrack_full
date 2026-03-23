import 'package:flutter/material.dart';
// import file service/api của dự án em vào đây (nếu có)

class NotificationController {
  // Hàm thuộc tính để call data gửi thông báo
  Future<bool> sendNotification({
    required BuildContext context,
    required String title,
    required String message,
  }) async {
    try {
      // 1. Chuẩn bị payload
      final Map<String, dynamic> data = {
        "title": title,
        "message": message,
        "type": "global", // Ví dụ: gửi cho toàn bộ user
      };

      // 2. Gọi API POST (Thay thế bằng code call API thực tế của em)
      // Ví dụ: final response = await apiService.post('/api/notifications', data: data);

      // Giả lập thời gian call API mất 1 giây
      await Future.delayed(const Duration(seconds: 1));

      // Giả sử API trả về thành công 200 OK
      return true;
    } catch (e) {
      print("Lỗi gửi thông báo: $e");
      return false;
    }
  }
}
