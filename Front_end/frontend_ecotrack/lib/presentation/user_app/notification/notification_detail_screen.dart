import 'package:flutter/material.dart';
import 'notification_screen.dart'; // Import model NotificationItem

class NotificationDetailScreen extends StatelessWidget {
  final NotificationItem item;

  const NotificationDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),

        // --- PHẦN ĐÃ SỬA ĐỔI ---
        title: Text(
          item.title, // Lấy title từ model
          maxLines:
              1, // Giới hạn 1 dòng để không bị vỡ giao diện nếu tên quá dài
          overflow: TextOverflow.ellipsis, // Nếu dài quá thì hiện dấu ...
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 21, // Chỉnh size chữ phù hợp với AppBar
          ),
        ),

        // -----------------------
        centerTitle:
            false, // (Tuỳ chọn) Canh trái title cho giống style iOS/hiện đại
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================
            // TAG + THỜI GIAN
            // ======================
            Row(
              children: [
                _tag(item.tag),
                const Spacer(),
                Text(
                  item.timeAgo,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9BAF97),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(thickness: 1, height: 1, color: Color(0xFFE5EDE2)),

            const SizedBox(height: 20),

            // ======================
            // NỘI DUNG
            // ======================
            Text(
              item.message,
              style: const TextStyle(
                fontSize: 15,
                height: 1.7,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 40),

            // ======================
            // GỢI Ý HÀNH ĐỘNG
            // ======================
            _actionHint(item.tag),
          ],
        ),
      ),
    );
  }

  // ... (Giữ nguyên các hàm _tag và _actionHint bên dưới)

  Widget _tag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F5D8),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF3D7D3A),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionHint(String tag) {
    String text;
    IconData icon;

    switch (tag) {
      case 'CAMPAIGN':
        text = 'Xem chiến dịch liên quan';
        icon = Icons.campaign_outlined;
        break;
      case 'REWARD':
        text = 'Kiểm tra phần thưởng';
        icon = Icons.card_giftcard_outlined;
        break;
      case 'ACHIEVEMENT':
        text = 'Xem thành tích đã đạt';
        icon = Icons.emoji_events_outlined;
        break;
      default:
        text = 'Thông báo hệ thống';
        icon = Icons.info_outline;
    }

    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3D7D3A)),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 13,
            color: Color(0xFF3D7D3A),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
