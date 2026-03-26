import 'dart:async';
import 'dart:convert';

import 'package:frontend_ecotrack/core/services/session_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SessionCheckerService {
  static Timer? _timer;
  static bool _isRunning = false;
  static bool _isChecking = false;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // Bắt đầu check session định kỳ với tần suất thấp để tránh spam API.
  static void startChecking({Duration interval = const Duration(minutes: 10)}) {
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

  // Check session local bằng JWT exp để không tạo request lặp.
  static Future<void> _checkSession() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final token = await _storage.read(key: 'jwt_token');
      if (token == null) {
        stopChecking();
        return;
      }

      if (_isJwtExpired(token)) {
        stopChecking();
        await SessionService.handleSessionExpired();
      }
    } catch (_) {
      // Nếu token parse lỗi thì bỏ qua, request thật sẽ tự xử lý 401.
    } finally {
      _isChecking = false;
    }
  }

  static bool _isJwtExpired(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return false;

    final payload =
        jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))))
            as Map<String, dynamic>;

    final exp = payload['exp'];
    if (exp is! num) return false;

    final nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return nowSeconds >= exp.toInt();
  }

  // Check session ngay lập tức (không chờ interval)
  static Future<void> checkNow() async {
    await _checkSession();
  }
}
