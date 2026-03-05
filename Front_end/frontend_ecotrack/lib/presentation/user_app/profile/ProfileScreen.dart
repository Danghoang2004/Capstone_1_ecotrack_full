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
      // Nền xanh pastel chuẩn Figma
      backgroundColor: const Color(0xFFF4F9F4), 
      body: FutureBuilder<ProfileView>(
        future: _viewFuture,
        builder: (context, snap) {
          // Loading
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)));
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
            color: Colors.transparent, // Để lộ nền xanh pastel
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(view),
                const SizedBox(height: 20),
                _buildAchievementsSection(view.badges),
                const SizedBox(height: 24),
                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 24),
                
                // Nút "Xem bảng xếp hạng"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Điều hướng sang trang Bảng Xếp Hạng
                      Navigator.pushNamed(context, '/leaderboard');
                    },
                    icon: const Icon(Icons.emoji_events_outlined, color: Colors.black),
                    label: const Text(
                      "Xem bảng xếp hạng",
                      style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
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
      fullName: 'Đang tải...',
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
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';

    final String? avatarNetworkUrl = view.avatarUrl.isNotEmpty
        ? '$baseUrl${view.avatarUrl}'
        : null;
    final displayName = view.fullName.isNotEmpty
        ? view.fullName
        : (view.username.isNotEmpty ? view.username : 'Người dùng');

    // ================= LOGIC LEVEL =================
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
      expandedHeight: 280.0, 
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF2E7D32), 
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

            // Lớp Gradient đen mờ đè lên ảnh để làm nổi bật chữ màu trắng
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
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
                      Icons.notifications_none,
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
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    "Cấp độ: ${view.levelName ?? 'Thành viên mới'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      view.location ?? 'Chưa cập nhật địa điểm',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

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
                          // Màu xanh lá chuối cho thanh nạp
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent, 
                          ),
                          minHeight: 7,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // =================== STATS GRID (4 Ô) ===================

  Widget _buildStatsGrid(ProfileView view) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, 
      mainAxisSpacing: 12, 
      childAspectRatio: 1.5, 
      children: [
        _statCard(
          color: const Color(0xFF2E7D32),
          icon: Icons.eco,
          title: view.points.toString(),
          subtitle: 'Eco Points',
        ),
        _statCard(
          color: const Color(0xFFF57C00), // Màu Cam
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
          color: const Color(0xFFFF7043), // Màu Cam San hô
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2, 
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ), 
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20, 
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =================== HUY HIỆU ===================
  
  Widget _buildAchievementsSection(List<BadgeModel> badges) {
    final effective = badges.take(6).toList();

    if (effective.isNotEmpty) {
      final row1 = effective.take(3).toList();
      final row2 = effective.length > 3 ? effective.sublist(3) : <BadgeModel>[];

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Huy hiệu thành tích',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: row1
                  .asMap()
                  .entries
                  .map((e) => Expanded(child: _buildAchievementFromBadge(e.value, e.key)))
                  .toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: row2
                  .asMap()
                  .entries
                  .map((e) => Expanded(child: _buildAchievementFromBadge(e.value, e.key + 3)))
                  .toList(),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Huy hiệu thành tích',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _StaticBadge(icon: Icons.recycling, label: 'Người tái chế', subLabel: '0 báo cáo')),
              Expanded(child: _StaticBadge(icon: Icons.energy_savings_leaf, label: 'Mục tiêu xanh', subLabel: '0 chiến dịch')),
              Expanded(child: _StaticBadge(icon: Icons.star, label: 'Ngôi sao', subLabel: 'Top 0')),
            ],
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(child: _StaticBadge(icon: Icons.shield, label: 'Thủ lĩnh', subLabel: '0 bạn bè')),
              Expanded(child: _StaticBadge(icon: Icons.card_giftcard, label: 'Chia sẻ', subLabel: '0 lượt mời')),
              Expanded(child: _StaticBadge(icon: Icons.workspace_premium, label: 'Eco Master', subLabel: 'Top 0')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementFromBadge(BadgeModel b, int index) {
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
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        if (subLabel.isNotEmpty)
          Text(
            subLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 10),
          ),
      ],
    );
  }

  // =================== HOẠT ĐỘNG GẦN ĐÂY ===================

  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    activities.sort(
    (a, b) => DateTime.parse(b.createdAt)
        .compareTo(DateTime.parse(a.createdAt)),
    );
    final previewActivities = activities.length > 2
      ? activities.sublist(0, 2)
      : activities;
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
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
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/activity_history');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Text(
                    "Xem tất cả >", 
                    style: TextStyle(
                      color: Color(0xFF388E3C), 
                      fontSize: 13, 
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...previewActivities.map((a) {
            final isGain = a.points >= 0;
            final pointsText = "${isGain ? '+' : ''}${a.points} điểm";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 255, 255, 255),
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
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${_formatDate(a.createdAt)} • ${_timeAgo(a.createdAt)}",
                          style: TextStyle(color: Colors.grey[700], fontSize: 10),
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
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      pointsText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

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
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          subLabel,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 10),
        ),
      ],
    );
  }
}