// lib/presentation/user_app/profile/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import '../../../core/services/user_service.dart' hide UnauthorizedException;
import 'package:frontend_ecotrack/core/errors/unauthorized_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required bool hideAppBar});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<ProfileView> _viewFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _viewFuture = _userService.getProfileView();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: FutureBuilder<ProfileView>(
        future: _viewFuture,
        builder: (context, snap) {
          // Loading
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error handling (including expired token)
          if (snap.hasError) {
            final error = snap.error;
            if (error is UnauthorizedException) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(context, '/login');
              });
              return const Center(
                child: Text('Phiên đăng nhập hết hạn, vui lòng đăng nhập lại.'),
              );
            }

            // Hiển thị skeleton để layout vẫn đẹp khi lỗi
            return _buildProfileSkeleton();
          }

          // Success
          final view = snap.data;
          if (view == null) {
            return _buildProfileSkeleton();
          }

          return _buildProfileContent(view);
        },
      ),
    );
  }

  // =================== UI CHÍNH ===================

  Widget _buildProfileContent(ProfileView view) {
    return CustomScrollView(
      slivers: <Widget>[
        _buildSliverAppBar(view),
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 16.0,
              top: 0,
            ),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(view),
                const SizedBox(height: 20),
                _buildAchievementsSection(view.badges),
                const SizedBox(height: 24),
                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Skeleton khi lỗi / không có data nhưng vẫn muốn giữ layout
  Widget _buildProfileSkeleton() {
    final placeholder = ProfileView(
      userId: 0,
      fullName: '',
      avatarUrl: '',
      email: '',
      username: '',
      location: null,
      levelName: null,
      levelIcon: null,
      points: 0,
      minPoints: 0,
      maxPoints: 100,
      reportCount: 0,
      groupCount: 0,
      rank: null,
      badges: List<BadgeModel>.filled(
        6,
        BadgeModel(
          badgeId: 0,
          badgeName: '',
          iconUrl: null,
          description: null,
          requirement: null,
          awardedAt: null,
        ),
      ),
      recentActivities: <ActivityModel>[],
    );

    return _buildProfileContent(placeholder);
  }

  // =================== HEADER / APPBAR ===================

  SliverAppBar _buildSliverAppBar(ProfileView view) {
    final String baseUrl = dotenv.env['API_BASE_URL']!;

    final String? avatarNetworkUrl = view.avatarUrl.isNotEmpty
        ? '$baseUrl${view.avatarUrl}'
        : null;
    final displayName = view.fullName.isNotEmpty
        ? view.fullName
        : (view.username.isNotEmpty ? view.username : 'Người dùng');

    // ================= LOGIC LEVEL (ĐÃ CẬP NHẬT) =================
    final double min = (view.minPoints ?? 0).toDouble();
    final double max = (view.maxPoints ?? 100).toDouble();
    final double cur = view.points.toDouble();

    // Tính phần trăm: (Điểm hiện tại - Điểm sàn) / (Điểm trần - Điểm sàn)
    double percent = 0.0;
    if (max > min) {
      percent = ((cur - min) / (max - min)).clamp(0.0, 1.0);
    } else {
      percent = 1.0; // Đạt cấp tối đa
    }
    // =============================================================

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 223, 233, 223),
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/anhprofile.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, _, __) => Container(
                alignment: Alignment.center,
                color: const Color(0xFF4CAF50),
                child: const Text(
                  'Ảnh không tìm thấy',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),

            // Icon Settings (Trái)
            Positioned(
              top: 28,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {},
              ),
            ),

            // Icon Group & Edit (Phải)
            Positioned(
              top: 28,
              right: 12,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.people_alt_outlined,
                      color: Colors.white,
                    ),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    onPressed: () async {
                      final result = await Navigator.pushNamed(
                        context,
                        '/editprofile',
                        arguments: view,
                      );
                      if (result == true) {
                        setState(() {
                          _viewFuture = _userService.getProfileView();
                        });
                      }
                    },
                  ),
                ],
              ),
            ),

            // Thông tin chính (Avatar, Name, Location, Level)
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarNetworkUrl != null
                      ? NetworkImage(avatarNetworkUrl)
                      : null,
                  child: avatarNetworkUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                  ),
                ),

                // Hiển thị Tên Cấp độ từ Database
                Text(
                  "Cấp độ: ${view.levelName ?? 'Thành viên mới'}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  view.location ?? 'Chưa cập nhật địa điểm',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 10),

                // Thanh tiến độ XP
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tiến độ lên cấp',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white70,
                            ),
                          ),
                          // Hiển thị điểm hiện tại / điểm tối đa của cấp độ
                          Text(
                            '${view.points} / ${view.maxPoints} XP',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== STATS GRID (4 Ô) - ĐÃ TỐI ƯU ===================

  Widget _buildStatsGrid(ProfileView view) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, // Tăng khoảng cách giữa các cột để thoáng hơn
      mainAxisSpacing: 12, // Tăng khoảng cách giữa các hàng
      childAspectRatio:
          1.5, // Tăng tỷ lệ này để làm các ô thấp xuống (thu nhỏ lại)
      children: [
        _statCard(
          color: const Color(0xFF2E7D32),
          icon: Icons.eco,
          title: view.points.toString(),
          subtitle: 'Eco Points',
        ),
        _statCard(
          color: const Color(0xFFFFA000),
          icon: Icons.camera_alt,
          title: view.reportCount.toString(),
          subtitle: 'Báo cáo rác',
        ),
        _statCard(
          color: const Color(0xFF3F51B5),
          icon: Icons.people,
          title: view.groupCount.toString(),
          subtitle: 'Chiến dịch',
        ),
        _statCard(
          color: const Color(0xFFE53935),
          icon: Icons.leaderboard,
          title: view.rank != null ? '#${view.rank}' : '-',
          subtitle: 'Xếp hạng',
        ),
      ],
    );
  }

  Widget _statCard({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      color: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2, // Thêm một chút đổ bóng cho chuyên nghiệp
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          // Căn giữa toàn bộ theo trục dọc và trục ngang
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ), // Giảm size icon một chút (từ 28 xuống 24)
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18, // Giảm size chữ một chút (từ 20 xuống 18)
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center, // Căn giữa nội dung text
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11, // Giảm nhẹ size sub (từ 12 xuống 11)
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== HUY HIỆU (2 HÀNG x 3) ===================

  Widget _buildAchievementsSection(List<BadgeModel> badges) {
    // map BadgeModel -> tối đa 6 item
    final effective = badges.take(6).toList();

    // nếu có data từ BE
    if (effective.isNotEmpty) {
      // tách 2 hàng
      final row1 = effective.take(3).toList();
      final row2 = effective.length > 3 ? effective.sublist(3) : <BadgeModel>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Huy hiệu thành tích',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row1
                .asMap()
                .entries
                .map((e) => _buildAchievementFromBadge(e.value, e.key))
                .toList(),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: row2
                .asMap()
                .entries
                .map((e) => _buildAchievementFromBadge(e.value, e.key + 3))
                .toList(),
          ),
        ],
      );
    }

    // fallback 6 thẻ xám giống file trên
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Huy hiệu thành tích',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StaticBadge(
              icon: Icons.recycling,
              label: 'Người tái chế',
              subLabel: '0 báo cáo',
            ),
            _StaticBadge(
              icon: Icons.energy_savings_leaf,
              label: 'Mục tiêu xanh',
              subLabel: '0 chiến dịch',
            ),
            _StaticBadge(
              icon: Icons.star,
              label: 'Ngôi sao',
              subLabel: 'Top 0',
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _StaticBadge(
              icon: Icons.shield,
              label: 'Thủ lĩnh',
              subLabel: '0 bạn bè',
            ),
            _StaticBadge(
              icon: Icons.card_giftcard,
              label: 'Chia sẻ',
              subLabel: '0 lượt mời',
            ),
            _StaticBadge(
              icon: Icons.workspace_premium,
              label: 'Eco Master',
              subLabel: 'Top 0',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAchievementFromBadge(BadgeModel b, int index) {
    // chọn icon / màu theo index để đẹp mắt
    final icons = [
      Icons.recycling,
      Icons.energy_savings_leaf,
      Icons.star,
      Icons.shield,
      Icons.card_giftcard,
      Icons.workspace_premium,
    ];
    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];

    final icon = icons[index % icons.length];
    final color = colors[index % colors.length];
    final achieved = (b.awardedAt != null) || (b.badgeName.isNotEmpty);

    final label = b.badgeName.isNotEmpty
        ? b.badgeName
        : 'Huy hiệu chưa mở khóa';
    final subLabel = b.description ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: achieved ? color.withOpacity(0.2) : Colors.grey[300],
          child: Icon(icon, size: 30, color: achieved ? color : Colors.grey),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
        if (subLabel.isNotEmpty)
          Text(
            subLabel,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
      ],
    );
  }

  // =================== HOẠT ĐỘNG GẦN ĐÂY ===================

  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      // Khi không có hoạt động
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hoạt động gần đây',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.event_note, color: Colors.grey[400]),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Chưa có hoạt động",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Có dữ liệu -> layout kiểu hình 2
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hoạt động gần đây',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        ...activities.map((a) {
          final isGain = a.points >= 0;
          final pointsText = "${isGain ? '+' : ''}${a.points} điểm";

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: const Color.fromARGB(
                255,
                255,
                255,
                255,
              ), // xám nhạt như mockup
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0x335EAC24),
                  child: const Icon(Icons.history, color: Color(0xFF5EAC24)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${_formatDate(a.createdAt)} • ${_timeAgo(a.createdAt)}",
                        style: TextStyle(color: Colors.grey[700], fontSize: 9),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pointsText,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // format thời gian
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (_) {
      return dateString;
    }
  }

  String _timeAgo(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final diff = DateTime.now().difference(dateTime);

      if (diff.inMinutes < 1) return 'Vừa xong';
      if (diff.inHours < 1) return '${diff.inMinutes} phút trước';
      if (diff.inHours < 24) return '${diff.inHours} giờ trước';
      return '${diff.inDays} ngày trước';
    } catch (_) {
      return dateString;
    }
  }

  /// hiện tại chỉ dùng để tạo khoảng cách trước grid
  Widget _buildProgressAndStats(ProfileView view) {
    return const SizedBox(height: 2);
  }
}

// =================== STATIC BADGE FALLBACK ===================

class _StaticBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;

  const _StaticBadge({
    Key? key,
    required this.icon,
    required this.label,
    required this.subLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: Colors.grey[300],
          child: Icon(icon, size: 30, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          subLabel,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}
