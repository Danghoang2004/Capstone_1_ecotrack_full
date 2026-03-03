import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/common/session_expired_dialog.dart';

class SessionService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static bool _isShowingDialog = false;

  static Future<void> handleSessionExpired() async {
    if (_isShowingDialog) {
      return; // Tránh hiển thị nhiều dialog cùng lúc
    }

    _isShowingDialog = true;

    // Lấy context TRƯỚC KHI logout
    final context = navigatorKey.currentContext;

    if (context == null) {
      _isShowingDialog = false;
      return;
    }

    if (!context.mounted) {
      _isShowingDialog = false;
      return;
    }

    // Hiển thị dialog TRƯỚC, sau đó mới logout khi user nhấn OK/X
    try {
      await SessionExpiredDialog.show(
        context,
        onOk: () async {
          _isShowingDialog = false;

          // Logout user
          final authService = AuthService();
          await authService.logout();

          // Navigate về login
          final finalContext = navigatorKey.currentContext;

          if (finalContext != null && finalContext.mounted) {
            Navigator.of(
              finalContext,
            ).pushNamedAndRemoveUntil('/login', (route) => false);
          } else {
            // Thử lại sau một chút
            await Future.delayed(const Duration(milliseconds: 100));
            final retryContext = navigatorKey.currentContext;
            if (retryContext != null && retryContext.mounted) {
              Navigator.of(
                retryContext,
              ).pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
        },
      );
    } catch (e, stackTrace) {
      _isShowingDialog = false;
    }
  }
}
