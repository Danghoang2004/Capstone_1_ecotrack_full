import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_screen.dart';

/// Nút chuông dùng trong AppBar
/// Hiển thị số thông báo chưa đọc (động)
class NotificationIconButton extends StatefulWidget {
  const NotificationIconButton({super.key});

  @override
  State<NotificationIconButton> createState() => _NotificationIconButtonState();
}

class _NotificationIconButtonState extends State<NotificationIconButton> {
  final NotificationService _service = NotificationService();
  int _unread = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadCount();
    // Poll every 30 seconds to keep badge reasonably fresh
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadCount());
  }

  Future<void> _loadCount() async {
    try {
      final c = await _service.getUnreadCount();
      if (mounted) {
        setState(() => _unread = c);
      }
    } catch (_) {
      // ignore errors silently for badge
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_none_rounded, color: Colors.black87),
          if (_unread > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(minWidth: 20, minHeight: 16),
                child: Text(
                  _unread > 99 ? '99+' : '$_unread',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      onPressed: () async {
        try {
          // Fetch latest notifications from backend and compute unread
          final items = await _service.getAll();
          int unreadCount = items.where((e) => !e.isRead).length;
          if (mounted) setState(() => _unread = unreadCount);

          // Open screen with initial items to ensure displayed list matches badge
          final changed = await Navigator.push<bool?>(
            context,
            MaterialPageRoute(builder: (_) => NotificationScreen(initialItems: items)),
          );

          // If screen reported changes (marked-as-read), reload count
          if (changed == true) {
            await _loadCount();
          } else {
            // still refresh to be safe
            await _loadCount();
          }
        } catch (e) {
          // If fetching fails, still try to open screen normally
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const NotificationScreen()),
          );
          _loadCount();
        }
      },
    );
  }
}
