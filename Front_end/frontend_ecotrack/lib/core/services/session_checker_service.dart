import 'dart:async';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionCheckerService {
  static Timer? _timer;
  static bool _isRunning = false;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static final ApiClient _apiClient = ApiClient(storage: _storage);

  // Bắt đầu check session định kỳ (mỗi 5 giây)
  static void startChecking({Duration interval = const Duration(seconds: 5)}) {
    if (_isRunning) {
      return; // Đã chạy rồi thì không chạy lại
    }

    _isRunning = true;
    _timer?.cancel(); // Hủy timer cũ nếu có

    _timer = Timer.periodic(interval, (timer) async {
      await _checkSession();
    });
  }

  // Dừng check session
  static void stopChecking() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
  }

  // Check session bằng cách gọi API profile (nhẹ nhất)
  static Future<void> _checkSession() async {
    try {
      // Kiểm tra xem có token không
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        // Không có token thì không cần check
        stopChecking(); // Dừng check nếu không có token
        return;
      }

      // Gọi API profile để check session
      // Nếu user bị disable, backend sẽ trả 401
      // ApiClient._handleResponse sẽ tự động gọi SessionService.handleSessionExpired()
      await _apiClient.get("/api/user/profile");
    } catch (e, stackTrace) {
      // Lỗi đã được xử lý trong ApiClient
    }
  }

  // Check session ngay lập tức (không chờ interval)
  static Future<void> checkNow() async {
    await _checkSession();
  }
}
