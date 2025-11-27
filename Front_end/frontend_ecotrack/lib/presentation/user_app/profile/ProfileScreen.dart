// lib/presentation/user_app/profile/ProfileScreen.dart
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart';
import '../../../core/services/user_service.dart' hide UnauthorizedException;
import 'package:frontend_ecotrack/core/errors/unauthorized_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

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
            padding: const EdgeInsets.all(16.0),
            color: Colors.grey[200],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProgressAndStats(view),
                const SizedBox(height: 5),
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
    final hasAvatar = view.avatarUrl.isNotEmpty;
    final displayName = view.fullName.isNotEmpty
        ? view.fullName
        : (view.username.isNotEmpty ? view.username : 'Người dùng');

    // Tính tiến độ (giữ nguyên logic cũ)
    final min = (view.minPoints ?? 0).toDouble();
    final max =
        (view.maxPoints ?? (view.points > 0 ? view.points.toDouble() : 100))
            .toDouble();
    final cur = view.points.toDouble();
    final percent = (max > min)
        ? ((cur - min) / (max - min)).clamp(0.0, 1.0)
        : 0.0;

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

            // Icon trên cùng
            Positioned(
              top: 28,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.settings, color: Colors.white),
                onPressed: () {},
              ),
            ),
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
                    icon: const Icon(Icons.share, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // Avatar + tên + location
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: hasAvatar
                      ? AssetImage('assets/images/avatar.jpg')
                      : null,
                  child: !hasAvatar
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
                  ),
                ),
                Text(
                  view.location ?? 'Chưa cập nhật địa điểm',
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 5),

                // Thanh tiến độ giống file trên
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
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            '${view.points}/${view.maxPoints} XP',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 8,
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

  // =================== STATS GRID (4 Ô) ===================

  Widget _buildStatsGrid(ProfileView view) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 1,
      mainAxisSpacing: 1,
      childAspectRatio: 1.1,
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
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 5),
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
              style: const TextStyle(color: Colors.white70, fontSize: 12),
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
