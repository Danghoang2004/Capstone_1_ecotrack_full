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
  late Future<List<BadgeModel>> _badgesFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _viewFuture = _userService.getProfileView();
    _badgesFuture = _userService
        .getAllBadges(); // 👉 Khởi tạo gọi dữ liệu huy hiệu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F4),
      body: FutureBuilder<ProfileView>(
        future: _viewFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            );
          }

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
            return _buildProfileSkeleton();
          }

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
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 0),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(view),
                const SizedBox(height: 20),

                // 👉 Khu vực Huy hiệu sẽ tự render bằng dữ liệu thật
                _buildAchievementsSection(context),

                const SizedBox(height: 24),
                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 24),

                // Nút "Xem bảng xếp hạng"
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/leaderboard');
                    },
                    icon: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.black,
                    ),
                    label: const Text(
                      "Xem bảng xếp hạng",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  /// Skeleton
  Widget _buildProfileSkeleton() {
    final placeholder = ProfileView(
      userId: 0, fullName: 'Đang tải...', avatarUrl: '', email: '', username: '',
      location: null, levelName: null, levelIcon: null, points: 0, minPoints: 0,
      maxPoints: 100, reportCount: 0, groupCount: 0, rank: null, badges: [], recentActivities: [],
    );
    return _buildProfileContent(placeholder);
  }

  // =================== HEADER / APPBAR ===================

  SliverAppBar _buildSliverAppBar(ProfileView view) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    final String? avatarNetworkUrl = view.avatarUrl.isNotEmpty ? '$baseUrl${view.avatarUrl}' : null;
    final displayName = view.fullName.isNotEmpty ? view.fullName : (view.username.isNotEmpty ? view.username : 'Người dùng');

    final double min = (view.minPoints ?? 0).toDouble();
    final double max = (view.maxPoints ?? 100).toDouble();
    final double cur = view.points.toDouble();
    double percent = max > min
        ? ((cur - min) / (max - min)).clamp(0.0, 1.0)
        : 1.0;

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
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
            ),
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
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
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
                          _badgesFuture = _userService
                              .getAllBadges(); // Refresh cả huy hiệu
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
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
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.shade600, borderRadius: BorderRadius.circular(12)),
                  child: Text("Cấp độ: ${view.levelName ?? 'Thành viên mới'}", style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(view.location ?? 'Chưa cập nhật địa điểm', style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
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
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
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

  // =================== STATS GRID ===================
  Widget _buildStatsGrid(ProfileView view) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.5,
      children: [
        _statCard(color: const Color(0xFF2E7D32), icon: Icons.eco, title: view.points.toString(), subtitle: 'Eco Points'),
        _statCard(color: const Color(0xFFF57C00), icon: Icons.camera_alt, title: view.reportCount.toString(), subtitle: 'Báo cáo rác'),
        _statCard(color: const Color(0xFF3F51B5), icon: Icons.people, title: view.groupCount.toString(), subtitle: 'Chiến dịch'),
        _statCard(color: const Color(0xFFFF7043), icon: Icons.leaderboard, title: view.rank != null ? '#${view.rank}' : '-', subtitle: 'Xếp hạng'),
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
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  // =================== HUY HIỆU (100% DỮ LIỆU THẬT) ===================
  Widget _buildAchievementsSection(BuildContext context) {
    return FutureBuilder<List<BadgeModel>>(
        future: _badgesFuture,
        builder: (context, snapshot) {
          // Đang chờ dữ liệu API
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              height: 150,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
            );
          }

          // Lấy dữ liệu thật từ Backend (API /api/user/badges/all)
          List<BadgeModel> realBadges = snapshot.data ?? [];

          realBadges.sort((a, b) {
            final aUnlocked = a.awardedAt != null;
            final bUnlocked = b.awardedAt != null;
            if (aUnlocked && !bUnlocked) return -1;
            if (!aUnlocked && bUnlocked) return 1;
            return 0;
          });

          final effective = realBadges.take(3).toList();

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề & Nút xem tất cả
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Huy hiệu thành tích', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/badge_list');
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                        child: Text("Xem tất cả >", style: TextStyle(color: Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Render Grid
                if (effective.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: effective.take(3).map((e) => Expanded(child: _buildAchievementFromBadge(e))).toList(),
                  ),
                  if (effective.length > 3) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: effective.skip(3).map((e) => Expanded(child: _buildAchievementFromBadge(e))).toList(),
                    ),
                  ]
                ] else ...[
                  const Center(child: Text("Chưa có huy hiệu nào", style: TextStyle(color: Colors.grey))),
                ]
              ],
            ),
          );
        }
    );
  }

  Widget _buildAchievementFromBadge(BadgeModel b) {
    final isUnlocked = b.awardedAt != null;
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String? imageUrl;
    if (b.iconUrl != null && b.iconUrl!.isNotEmpty) {
      imageUrl = b.iconUrl!.startsWith('http') ? b.iconUrl : '$baseUrl/images/${b.iconUrl}';
    }

    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(color: isUnlocked ? Colors.green.shade50 : Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
          child: Center(
            child: !isUnlocked
                ? const Icon(Icons.lock, color: Colors.amber, size: 28)
                : (imageUrl != null
                ? Image.network(imageUrl, width: 40, height: 40, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.star, color: Colors.green))
                : const Icon(Icons.star, color: Colors.green, size: 30)),
          ),
        ),
        const SizedBox(height: 8),
        Text(b.badgeName.isNotEmpty ? b.badgeName : 'Huy hiệu', textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        Text(b.description ?? (isUnlocked ? 'Thường' : 'Khóa'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 10)),
      ],
    );
  }

  // =================== HOẠT ĐỘNG GẦN ĐÂY ===================
  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Hoạt động gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  CircleAvatar(radius: 24, backgroundColor: Colors.grey[200], child: Icon(Icons.event_note, color: Colors.grey[400])),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Chưa có hoạt động", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey))),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Hoạt động gần đây', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/activity_history');
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                  child: Text("Xem tất cả >", style: TextStyle(color: Color(0xFF388E3C), fontSize: 13, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...activities.map((a) {
            final isGain = a.points >= 0;
            final pointsText = "${isGain ? '+' : ''}${a.points} điểm";

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(radius: 22, backgroundColor: Color(0x335EAC24), child: Icon(Icons.history, color: Color(0xFF5EAC24))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.description, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text("${_formatDate(a.createdAt)} • ${_timeAgo(a.createdAt)}", style: TextStyle(color: Colors.grey[700], fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(999)),
                    child: Text(pointsText, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87)),
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
    } catch (_) { return dateString; }
  }
}
