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
    // Gọi API lấy tiến độ huy hiệu (bao gồm claimed + unclaimed)
    _badgesFuture = _userService.getBadgeProgressBadges();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgLight = Color(0xFFF4FBF8);
    const Color primaryGreen = Color(0xFF2E7D32);

    return Scaffold(
      backgroundColor: bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        forceMaterialTransparency: true,
        centerTitle: true,
        title: const Text(
          "Danh Sách Huy Hiệu",
          style: TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black), // nút back
      ),
      body: FutureBuilder<List<BadgeModel>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: primaryGreen),
            );
          }
          if (snapshot.hasError) {
            return Center(child: Text("Lỗi: ${snapshot.error}"));
          }

          final allBadges = snapshot.data ?? [];

          // Phân loại
          final earnedBadges = allBadges.where((b) => b.isClaimed).toList();
          final lockedBadges = allBadges.where((b) => !b.isClaimed).toList();

          List<BadgeModel> displayBadges;
          if (_selectedTabIndex == 1)
            displayBadges = earnedBadges;
          else if (_selectedTabIndex == 2)
            displayBadges = lockedBadges;
          else
            displayBadges = allBadges;

          return Column(
            children: [
              // Thanh Tabs Filter
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
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
                    ? const Center(
                        child: Text(
                          "Không có huy hiệu nào trong mục này",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        // Bắt buộc phải có dòng gridDelegate này
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
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
        },
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
    final isLocked = !badge.isClaimed;

    // Xử lý đường dẫn ảnh từ Backend
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String? imageUrl;
    if (badge.iconUrl != null && badge.iconUrl!.isNotEmpty) {
      imageUrl = badge.iconUrl!.startsWith('http')
          ? badge.iconUrl
          : '$baseUrl${badge.iconUrl}';
    }

    // Đổi màu nền nhẹ dựa theo trạng thái khóa/mở
    Color imageBgColor = isLocked
        ? Colors.grey.shade300
        : const Color(0xFFE3F2FD);

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
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Always try to show the image (or fallback icon)
                    imageUrl != null
                        ? Image.network(
                            imageUrl,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                  child: Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 48,
                                  ),
                                ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 48,
                            ),
                          ),

                    // If locked, dim the image and show lock overlay
                    if (isLocked) ...[
                      Container(color: Colors.black.withOpacity(0.35)),
                      const Center(
                        child: Icon(Icons.lock, color: Colors.amber, size: 48),
                      ),
                    ],
                  ],
                ),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Mô tả
          Text(
            isLocked ? "Chưa mở khóa" : (badge.description ?? "Thường"),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
          const SizedBox(height: 4),

          // Điểm yêu cầu hoặc Ngày nhận
          Text(
            isLocked ? "${badge.pointsRequired} điểm" : (badge.awardedAt ?? ""),
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
