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
  static const Color _pageBg = Color(0xFFF4FBF8);
  static const Color _surfaceCard = Color(0xFFFCFEFC);
  static const Color _surfaceBorder = Color(0xFFE0ECE3);
  static const Color _titleText = Color(0xFF22372A);
  static const Color _mutedText = Color(0xFF6A7D71);
  static const Color _primaryGreen = Color(0xFF2F7D4B);

  late Future<ProfileView> _viewFuture;
  late Future<List<BadgeModel>> _badgesFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _viewFuture = _userService.getProfileView();
    _badgesFuture = _userService
        .getAllBadges(); // Khởi tạo gọi dữ liệu huy hiệu
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
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
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
            color: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatsGrid(view),
                const SizedBox(height: 10),

                _buildAchievementsSection(context),
                const SizedBox(height: 14),

                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/ranking');
                    },
                    icon: const Icon(
                      Icons.emoji_events_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      "Xem bảng xếp hạng",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryGreen,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 70),
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
      badges: [],
      recentActivities: [],
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

    final double min = (view.minPoints ?? 0).toDouble();
    final double max = (view.maxPoints ?? 100).toDouble();
    final double cur = view.points.toDouble();
    double percent = max > min
        ? ((cur - min) / (max - min)).clamp(0.0, 1.0)
        : 1.0;

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      backgroundColor: _primaryGreen,
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
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black45)],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Cấp độ: ${view.levelName ?? 'Thành viên mới'}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                    Text(
                      view.location ?? 'Chưa cập nhật địa điểm',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 11),
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
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${view.points} / ${view.maxPoints} XP',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: percent,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.greenAccent,
                          ),
                          minHeight: 6,
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

  // =================== STATS GRID ===================
  Widget _buildStatsGrid(ProfileView view) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.2,
      children: [
        _statCard(
          accentColor: const Color(0xFF1F8F53),
          surfaceTint: const Color(0xFFD8F1E1),
          iconBg: const Color(0xFFCDEEDB),
          icon: Icons.eco,
          title: view.points.toString(),
          subtitle: 'Eco Points',
        ),
        _statCard(
          accentColor: const Color(0xFFE07A00),
          surfaceTint: const Color(0xFFFFE6C9),
          iconBg: const Color(0xFFFFDDAF),
          icon: Icons.camera_alt,
          title: view.reportCount.toString(),
          subtitle: 'Báo cáo rác',
        ),
        _statCard(
          accentColor: const Color(0xFF3F4FBE),
          surfaceTint: const Color(0xFFDCE1FF),
          iconBg: const Color(0xFFC8D0FF),
          icon: Icons.people,
          title: view.groupCount.toString(),
          subtitle: 'Chiến dịch',
        ),
        _statCard(
          accentColor: const Color(0xFFD85B39),
          surfaceTint: const Color(0xFFFFDFD6),
          iconBg: const Color(0xFFFFCFC0),
          icon: Icons.leaderboard,
          title: view.rank != null ? '#${view.rank}' : '-',
          subtitle: 'Xếp hạng',
        ),
      ],
    );
  }

  Widget _statCard({
    required Color accentColor,
    required Color surfaceTint,
    required Color iconBg,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [surfaceTint, surfaceTint.withOpacity(0.55)],
        ),
        border: Border.all(color: accentColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          const BoxShadow(
            color: Color(0x10FFFFFF),
            blurRadius: 4,
            offset: Offset(0, -1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconBg,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF5B6D63),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.45),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
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
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: _surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _surfaceBorder),
              boxShadow: [
                BoxShadow(
                  color: const Color(0x1A284737),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(color: _primaryGreen),
            ),
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
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _surfaceBorder),
            boxShadow: [
              BoxShadow(
                color: const Color(0x1A284737),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Huy hiệu thành tích',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _titleText,
                      letterSpacing: 0.3,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, '/badge_list');
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Text(
                        "Xem tất cả >",
                        style: TextStyle(
                          color: _primaryGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Render Grid
              if (effective.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: effective
                      .take(3)
                      .map(
                        (e) => Expanded(child: _buildAchievementFromBadge(e)),
                      )
                      .toList(),
                ),
                if (effective.length > 3) ...[
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: effective
                        .skip(3)
                        .map(
                          (e) => Expanded(child: _buildAchievementFromBadge(e)),
                        )
                        .toList(),
                  ),
                ],
              ] else ...[
                const Center(
                  child: Text(
                    "Chưa có huy hiệu nào",
                    style: TextStyle(color: _mutedText, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementFromBadge(BadgeModel b) {
    final isUnlocked = b.awardedAt != null;
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    String? imageUrl;
    if (b.iconUrl != null && b.iconUrl!.isNotEmpty) {
      imageUrl = b.iconUrl!.startsWith('http')
          ? b.iconUrl
          : '$baseUrl/images/${b.iconUrl}';
    }

    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: isUnlocked ? Colors.green.shade50 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: !isUnlocked
                ? const Icon(Icons.lock, color: Colors.amber, size: 28)
                : (imageUrl != null
                      ? Image.network(
                          imageUrl,
                          width: 40,
                          height: 40,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.star,
                            color: Colors.green,
                            size: 28,
                          ),
                        )
                      : const Icon(Icons.star, color: Colors.green, size: 28)),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          b.badgeName.isNotEmpty ? b.badgeName : 'Huy hiệu',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          b.description ?? (isUnlocked ? 'Thường' : 'Khóa'),
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
      ],
    );
  }

  // =================== HOẠT ĐỘNG GẦN ĐÂY ===================
  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _surfaceCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: const Color(0x1A284737),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hoạt động gần đây',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: _titleText,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE3EEE7)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFFDDEFE4),
                    child: const Icon(Icons.event_note, color: _primaryGreen),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Chưa có hoạt động",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: _mutedText,
                        fontSize: 13,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: const Color(0x1A284737),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hoạt động gần đây',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _titleText,
                  letterSpacing: 0.3,
                ),
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
                      color: _primaryGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...activities.map((a) {
            final isGain = a.points >= 0;
            final pointsText = "${isGain ? '+' : ''}${a.points} điểm";

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xFFF4FAF6),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE3EEE7), width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: Color(0x333A8E59),
                    child: Icon(Icons.history, color: _primaryGreen, size: 20),
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
                            color: _titleText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          "${_formatDate(a.createdAt)} • ${_timeAgo(a.createdAt)}",
                          style: TextStyle(color: _mutedText, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isGain
                          ? const Color(0xFFE4F4EA)
                          : const Color(0xFFFBE4DF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isGain
                            ? const Color(0xFFCAE7D4)
                            : const Color(0xFFF1CAC1),
                      ),
                    ),
                    child: Text(
                      pointsText,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isGain
                            ? const Color(0xFF266F45)
                            : const Color(0xFFB3472D),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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
