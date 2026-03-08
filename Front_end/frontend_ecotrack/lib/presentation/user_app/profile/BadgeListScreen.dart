import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import '../../../core/services/user_service.dart';

class BadgeListScreen extends StatefulWidget {
  // Bỏ biến badges đi, vì mình sẽ tự gọi API
  const BadgeListScreen({super.key});

  @override
  State<BadgeListScreen> createState() => _BadgeListScreenState();
}

class _BadgeListScreenState extends State<BadgeListScreen> {
  int _selectedTabIndex = 0; 
  late Future<List<BadgeModel>> _badgesFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    // Gọi API lấy danh sách huy hiệu
    _badgesFuture = _userService.getAllBadges(); 
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF4F9F4);
    const Color primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        // ... (Giữ nguyên phần AppBar của bạn)
      ),
      body: FutureBuilder<List<BadgeModel>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryGreen));
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }
          
          final allBadges = snapshot.data ?? [];
          
          // Phân loại
          final earnedBadges = allBadges.where((b) => b.awardedAt != null).toList();
          final lockedBadges = allBadges.where((b) => b.awardedAt == null).toList();

          List<BadgeModel> displayBadges;
          if (_selectedTabIndex == 1) displayBadges = earnedBadges;
          else if (_selectedTabIndex == 2) displayBadges = lockedBadges;
          else displayBadges = allBadges;

          return Column(
            children: [
              // Thanh Tabs Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  children: [
                    _buildTabButton("Tất cả", 0, null),
                    const SizedBox(width: 12),
                    _buildTabButton("Đã kiếm", 1, earnedBadges.length),
                    const SizedBox(width: 12),
                    _buildTabButton("Khóa", 2, lockedBadges.length),
                  ],
                ),
              ),

              // Lưới hiển thị
             Expanded(
                child: displayBadges.isEmpty
                    ? const Center(child: Text("Không có huy hiệu nào trong mục này", style: TextStyle(color: Colors.grey)))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        // Bắt buộc phải có dòng gridDelegate này
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, 
                          childAspectRatio: 0.8, 
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: displayBadges.length,
                        // Bắt buộc phải có dòng itemBuilder này
                        itemBuilder: (context, index) {
                          return _buildBadgeCard(displayBadges[index]);
                        },
                      ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildTabButton(String title, int index, int? count) {
    final isSelected = _selectedTabIndex == index;
    final displayTitle = count != null ? "$title ($count)" : title;

    return GestureDetector(
      onTap: () => setState(() => _selectedTabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2E7D32) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          displayTitle,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // Thẻ Huy hiệu chuẩn Figma
  Widget _buildBadgeCard(BadgeModel badge) {
    final isLocked = badge.awardedAt == null;
    
    // Xử lý đường dẫn ảnh từ Backend
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String? imageUrl;
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
      imageUrl = badge.iconUrl!.startsWith('http') ? badge.iconUrl : '$baseUrl${badge.iconUrl}';
    }

    // Đổi màu nền nhẹ dựa theo trạng thái khóa/mở
    Color imageBgColor = isLocked ? Colors.grey.shade300 : const Color(0xFFE3F2FD); 

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Khối chứa Ảnh Huy hiệu
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: imageBgColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isLocked
                    ? const Icon(Icons.lock, color: Colors.amber, size: 40)
                    : (imageUrl != null
                        ? Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.star, color: Colors.orange, size: 40))
                        : const Icon(Icons.star, color: Colors.orange, size: 40)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Tên huy hiệu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              badge.badgeName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 4),
          
          // Độ hiếm
          Text(
            isLocked ? "Chưa mở khóa" : (badge.description ?? "Thường"),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 4),

          // Ngày nhận hoặc Yêu cầu
          Text(
            isLocked ? (badge.requirement ?? "Cố gắng lên!") : (badge.awardedAt ?? ""),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isLocked ? Colors.grey : const Color(0xFF2E7D32),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}