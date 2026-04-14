import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/data/models/NotificationModelAdmin.dart';
import 'create_notification_screen.dart';
import 'package:intl/intl.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // Lấy dữ liệu từ Backend thông qua Service chung
  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _notificationService.getAdminNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi lấy danh sách Admin: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditDialog(NotificationModel item) async {
    final titleController = TextEditingController(text: item.title);
    final messageController = TextEditingController(text: item.message);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông báo'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiêu đề'),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập tiêu đề',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nội dung'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập nội dung thông báo',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      titleController.dispose();
      messageController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final message = messageController.text.trim();
    titleController.dispose();
    messageController.dispose();

    if (title.isEmpty || message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề và nội dung không được để trống.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isMutating = true);
    final success = await _notificationService.updateAdminNotification(
      id: item.id,
      title: title,
      message: message,
    );
    if (mounted) {
      setState(() => _isMutating = false);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông báo.'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể chỉnh sửa. Backend có thể chưa hỗ trợ endpoint cập nhật.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa thông báo'),
          content: Text(
            'Bạn có chắc muốn xóa thông báo "${item.title}"? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isMutating = true);
    final success = await _notificationService.deleteAdminNotification(item.id);
    if (mounted) {
      setState(() => _isMutating = false);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thông báo.'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Không thể xóa. Backend có thể chưa hỗ trợ endpoint xóa.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quản Lý Thông Báo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Tạo thông báo mới",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                ),
                onPressed: () async {
                  // Mở form tạo thông báo dạng dialog ở giữa màn hình
                  await showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (dialogContext) =>
                        const CreateNotificationScreen(),
                  );
                  _fetchNotifications();
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                ? const Center(child: Text("Chưa có thông báo nào."))
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final item = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(
                              0xFF5EAC24,
                            ).withOpacity(0.1),
                            child: const Icon(
                              Icons.notifications,
                              color: Color(0xFF5EAC24),
                            ),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitleTextStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          isThreeLine: true,
                          titleAlignment: ListTileTitleAlignment.top,
                          dense: false,
                          minVerticalPadding: 8,
                          horizontalTitleGap: 12,
                          trailing: SizedBox(
                            width: 140,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy').format(item.createdAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                PopupMenuButton<String>(
                                  enabled: !_isMutating,
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      await _showEditDialog(item);
                                    }
                                    if (value == 'delete') {
                                      await _deleteNotification(item);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Chỉnh sửa'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: Colors.red,
                                          ),
                                          SizedBox(width: 8),
                                          Text('Xóa'),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
