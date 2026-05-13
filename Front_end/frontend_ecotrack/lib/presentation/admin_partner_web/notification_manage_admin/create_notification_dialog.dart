import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';

class CreateNotificationDialog extends StatefulWidget {
  const CreateNotificationDialog({super.key});

  @override
  State<CreateNotificationDialog> createState() =>
      _CreateNotificationDialogState();
}

class _CreateNotificationDialogState extends State<CreateNotificationDialog> {
  static const List<_AudienceOption> _audienceOptions = [
    _AudienceOption('ROLE_USER', 'Người dùng'),
    _AudienceOption('ROLE_ENVIRONMENT', 'Đội môi trường'),
    _AudienceOption('ROLE_ALL', 'Tất cả vai trò'),
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final NotificationService _notificationService = NotificationService();

  bool _isLoading = false;
  String _selectedAudienceRole = 'ROLE_USER';

  void _submitNotification() async {
    String title = _titleController.text.trim();
    String message = _messageController.text.trim();

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập đầy đủ tiêu đề và nội dung!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _notificationService.sendBroadcastNotification(
      title: title,
      message: message,
      audienceRole: _selectedAudienceRole,
      notificationType: 'SYSTEM',
      scheduledTime: null,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi thông báo thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gửi thất bại. Vui lòng thử lại!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Gửi thông báo hệ thống',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Đối tượng nhận'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedAudienceRole,
                items: _audienceOptions
                    .map(
                      (option) => DropdownMenuItem<String>(
                        value: option.value,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: _isLoading
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() => _selectedAudienceRole = value);
                      },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const Text('Tiêu đề:'),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Nhập tiêu đề...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Nội dung thông báo:'),
              const SizedBox(height: 8),
              TextField(
                controller: _messageController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Nhập nội dung cần thông báo tới người dùng...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitNotification,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5EAC24),
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
                  'Gửi thông báo',
                  style: TextStyle(color: Colors.white),
                ),
        ),
      ],
    );
  }
}

class _AudienceOption {
  const _AudienceOption(this.value, this.label);

  final String value;
  final String label;
}
