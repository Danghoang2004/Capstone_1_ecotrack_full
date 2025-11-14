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

            // Show UI skeleton even on generic error so layout stays consistent
            return _buildProfileSkeleton();
          }

          // Success: data may be null or populated
          final view = snap.data;
          if (view == null) {
            return _buildProfileSkeleton();
          }

          return _buildProfileContent(view);
        },
      ),
    );
  }

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
                const SizedBox(height: 15),
                _buildBadgesHeader(),
                const SizedBox(height: 8),
                _buildBadgesSection(view.badges),
                const SizedBox(height: 20),
                _buildRecentActivitiesHeader(),
                const SizedBox(height: 8),
                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ------------------------------
  // Build a skeleton (placeholders) for cases: error, no data, or loading fallback
  // ------------------------------
  Widget _buildProfileSkeleton() {
    // create an empty (zero) ProfileView-like presentation using placeholder values
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
      recentActivities: List<ActivityModel>.empty(growable: true),
    );

    return _buildProfileContent(placeholder);
  }

  // ------------------------------
  // AppBar / Header with avatar, name, location, progress bar
  // ------------------------------
  SliverAppBar _buildSliverAppBar(ProfileView view) {
    final hasAvatar = view.avatarUrl.isNotEmpty;
    final displayName = view.fullName.isNotEmpty
        ? view.fullName
        : (view.username.isNotEmpty ? view.username : 'Người dùng');

    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.green[400],
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isCollapsed = constraints.maxHeight <= kToolbarHeight + 50;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.parallax,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // BG Image
                if (hasAvatar)
                  Image.asset('assets/images/anhprofile.jpg', fit: BoxFit.cover)
                else
                  Container(color: Colors.green[400]),

                // Dark overlay
                Container(color: Colors.black.withOpacity(0.25)),

                Positioned(
                  top: 30,
                  left: 16,
                  child: _headerIcon(Icons.settings),
                ),

                Positioned(
                  top: 30,
                  right: 16,
                  child: Row(
                    children: [
                      _headerIcon(Icons.notifications),
                      const SizedBox(width: 10),
                      _headerIcon(Icons.share),
                    ],
                  ),
                ),

                // Progress bar
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 16,
                    ),
                    child: _buildProgressBar(view),
                  ),
                ),

                // Avatar + Name overlay
                Positioned(
                  bottom: 80,
                  left: 0,
                  right: 0,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: isCollapsed ? 24 : 30,
                        backgroundColor: Colors.white,
                        backgroundImage: hasAvatar
                            ? AssetImage('assets/images/avatar.jpg')
                            : null,
                        child: !hasAvatar
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),

                      if (!isCollapsed)
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),

                      if (!isCollapsed) const SizedBox(height: 1),

                      if (!isCollapsed)
                        Text(
                          view.location ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _headerIcon(IconData icon) {
    return Icon(icon, color: Colors.white, size: 18);
  }

  // progress bar showing points / level bounds
  Widget _buildProgressBar(ProfileView view) {
    final min = (view.minPoints ?? 0).toDouble();
    final max =
        (view.maxPoints ?? (view.points > 0 ? view.points.toDouble() : 100))
            .toDouble();
    final cur = view.points.toDouble();
    final percent = (max > min)
        ? ((cur - min) / (max - min)).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white70,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tiến độ lên cấp',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: percent,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${view.points}/${(view.maxPoints ?? 0)} XP',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ------------------------------
  // Colored stat grid (4 boxes) — always present
  // ------------------------------
  Widget _buildStatsGrid(ProfileView view) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _statCard(
                // Eco Points
                color: Colors.green[700]!,
                title: view.points.toString(),
                subtitle: 'Eco Points',
                icon: Icons.eco,
                flex: 1,
              ),
              const SizedBox(width: 12),
              _statCard(
                color: Colors.orange[700]!,
                title: view.reportCount.toString(),
                subtitle: 'Báo cáo rác',
                icon: Icons.camera_alt,
                flex: 1,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard(
                color: Colors.blue[700]!,
                title: view.groupCount.toString(),
                subtitle: 'Chiến dịch',
                icon: Icons.group,
                flex: 1,
              ),
              const SizedBox(width: 12),
              _statCard(
                color: Colors.red[300]!,
                title: view.rank != null ? '#${view.rank}' : '-',
                subtitle: 'Xếp hạng',
                icon: Icons.emoji_events,
                flex: 1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard({
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
    required int flex,
  }) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 110,
        width: 50,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  // header for badges section
  Widget _buildBadgesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Huy hiệu thành tích',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // you may place a 'Xem tất cả' button here
      ],
    );
  }

  // badges: always show 6 slots (placeholder if badgeName is empty)
  Widget _buildBadgesSection(List<BadgeModel> badges) {
    // ensure length at least 6 for UI layout
    final displayList = List<BadgeModel>.from(badges);
    while (displayList.length < 6) {
      displayList.add(
        BadgeModel(
          badgeId: 0,
          badgeName: '',
          iconUrl: null,
          description: null,
          requirement: null,
          awardedAt: null,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayList.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final b = displayList[index];
              final bool has =
                  (b.badgeId != 0 && (b.badgeName?.isNotEmpty ?? false));
              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: has
                        ? Colors.transparent
                        : Colors.grey[200],
                    backgroundImage: has && b.iconUrl != null
                        ? NetworkImage(b.iconUrl!)
                        : null,
                    child: !has
                        ? Icon(Icons.lock, color: Colors.grey[400])
                        : null,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: 80,
                    child: Text(
                      has ? b.badgeName : 'Chưa có',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: has ? Colors.black : Colors.grey[500],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: const [
        Text(
          'Hoạt động gần đây',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        // optional action button
      ],
    );
  }

  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      // 🔹 Khi không có hoạt động
      return Container(
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
      );
    }

    // 🔹 Khi có dữ liệu hoạt động
    return Column(
      children: activities.map((a) {
        return Container(
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon tròn bên trái
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0x335EAC24), // xanh nhạt
                child: const Icon(
                  Icons.history,
                  color: Color(0xFF5EAC24), // xanh chính
                ),
              ),
              const SizedBox(width: 12),

              // Nội dung chữ
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.description,
                      style: const TextStyle(color: Colors.black, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "+${a.points} điểm • ${_formatDate(a.createdAt)}",
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // 🔹 format thời gian gọn gàng
  String _formatDate(String dateString) {
    if (dateString.isEmpty) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return "${dateTime.day}/${dateTime.month}/${dateTime.year}";
    } catch (_) {
      return dateString;
    }
  }

  /// Hiển thị progress bar (tiến độ lên cấp) và khoảng cách trước khi grid thống kê
  Widget _buildProgressAndStats(ProfileView view) {
    return Column(
      children: [
        const SizedBox(height: 2),
        // (nếu muốn có thêm 1 hàng tóm tắt nhỏ, có thể mở comment dưới)
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Text('${view.points} Eco Points', style: TextStyle(fontWeight: FontWeight.bold)),
        //     Text(view.location ?? '-', style: TextStyle(color: Colors.grey)),
        //   ],
        // ),
      ],
    );
  }
}
