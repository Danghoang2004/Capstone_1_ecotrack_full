import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/data/models/ProfileView.dart'
    show ProfileView, BadgeModel, ActivityModel;
import '../../../core/services/user_service.dart' hide UnauthorizedException;
import 'package:frontend_ecotrack/core/errors/unauthorized_exception.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required bool hideAppBar});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _pageBg = Color(0xFFFAFDFC);
  static const Color _cardBg = Color(0xFFFFFFFF);
  static const Color _primaryGreen = Color(0xFF2F7D4B);
  static const Color _accentGreen = Color(0xFF1F8F53);
  static const Color _textDark = Color(0xFF1A3A2E);
  static const Color _textMuted = Color(0xFF6A8A7A);
  static const Color _borderLight = Color(0xFFE8F0EC);

  late Future<ProfileView> _viewFuture;
  late Future<List<BadgeModel>> _badgesFuture;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _viewFuture = _userService.getProfileView();
    _badgesFuture = _userService.getBadgeProgressBadges();
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
              child: CircularProgressIndicator(color: _primaryGreen),
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

  Widget _buildProfileContent(ProfileView view) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          floating: true,
          snap: true,
          centerTitle: true,
          title: const Text(
            'Hồ sơ cá nhân',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _textDark,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit, color: _textDark, size: 22),
              onPressed: () async {
                final result = await Navigator.pushNamed(
                  context,
                  '/editprofile',
                  arguments: view,
                );
                if (result == true) {
                  setState(() {
                    _viewFuture = _userService.getProfileView();
                    _badgesFuture = _userService.getBadgeProgressBadges();
                  });
                }
              },
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileHeader(view),
                const SizedBox(height: 20),
                _buildProgressCard(view),
                const SizedBox(height: 20),
                _buildStatsHorizontal(view),
                const SizedBox(height: 20),
                _buildAchievementsSection(context),
                const SizedBox(height: 20),
                _buildRecentActivitySection(view.recentActivities),
                const SizedBox(height: 20),
                _buildRankingButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }

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

  Widget _buildProfileHeader(ProfileView view) {
    final String? avatarUrl = _resolveAvatarUrl(view.avatarUrl);
    final displayName = view.fullName.isNotEmpty
        ? view.fullName
        : (view.username.isNotEmpty ? view.username : 'Người dùng');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildProfileAvatar(avatarUrl),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _textDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_accentGreen, _primaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Cấp độ: ${view.levelName ?? 'Thành viên mới'}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: _textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        view.location ?? 'Chưa cập nhật',
                        style: const TextStyle(fontSize: 12, color: _textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(ProfileView view) {
    final double min = (view.minPoints ?? 0).toDouble();
    final double max = (view.maxPoints ?? 100).toDouble();
    final double cur = view.points.toDouble();
    double percent = max > min
        ? ((cur - min) / (max - min)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _accentGreen.withOpacity(0.1),
            _primaryGreen.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                'Tiến độ lên cấp',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${view.points} / ${view.maxPoints} XP',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _accentGreen,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: Colors.grey.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(_accentGreen),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(percent * 100).toStringAsFixed(0)}% hoàn thành',
                style: const TextStyle(
                  fontSize: 13,
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Còn ${(view.maxPoints - view.points).toString()} XP',
                style: const TextStyle(
                  fontSize: 13,
                  color: _accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsHorizontal(ProfileView view) {
    return SizedBox(
      height: 107,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildStatItem(
            icon: Icons.eco,
            label: 'Eco Points',
            value: view.points.toString(),
            accentColor: const Color(0xFF1F8F53),
            bgColor: const Color(0xFFE3F7ED),
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            icon: Icons.camera_alt,
            label: 'Báo cáo',
            value: view.reportCount.toString(),
            accentColor: const Color(0xFFE07A00),
            bgColor: const Color(0xFFFFF3E0),
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            icon: Icons.people,
            label: 'Chiến dịch',
            value: view.groupCount.toString(),
            accentColor: const Color(0xFF3F4FBE),
            bgColor: const Color(0xFFEBF0FF),
          ),
          const SizedBox(width: 10),
          _buildStatItem(
            icon: Icons.leaderboard,
            label: 'Xếp hạng',
            value: view.rank != null ? '#${view.rank}' : '-',
            accentColor: const Color(0xFFD85B39),
            bgColor: const Color(0xFFFFE4DD),
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color accentColor,
    required Color bgColor,
  }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accentColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accentColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: _textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context) {
    return FutureBuilder<List<BadgeModel>>(
      future: _badgesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSectionContainer(
            title: 'Huy hiệu thành tích',
            onViewAll: () => Navigator.pushNamed(context, '/badge_list'),
            child: const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final badges = snapshot.data ?? [];

        if (badges.isEmpty) {
          return _buildEmptyBadge();
        }

        // sort unlocked first
        badges.sort((a, b) {
          final aUnlocked = a.awardedAt != null;
          final bUnlocked = b.awardedAt != null;
          if (aUnlocked && !bUnlocked) return -1;
          if (!aUnlocked && bUnlocked) return 1;
          return 0;
        });

        final featured = badges.first;
        final others = badges.skip(1).take(4).toList();

        return _buildSectionContainer(
          title: 'Huy hiệu thành tích',
          onViewAll: () => Navigator.pushNamed(context, '/badge_list'),
          child: Column(
            children: [
              _buildFeaturedBadge(featured),
              const SizedBox(height: 8), // ⬅ giảm spacing
              _buildBadgeHorizontal(others),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeaturedBadge(BadgeModel badge) {
    final isUnlocked = badge.awardedAt != null;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: isUnlocked
            ? _accentGreen.withOpacity(0.12)
            : const Color(0xFFEDEDED),
        border: Border.all(
          color: isUnlocked
              ? _accentGreen.withOpacity(0.4)
              : Colors.grey.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked
                  ? _accentGreen.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.25),
            ),
            child: Icon(
              isUnlocked ? Icons.emoji_events : Icons.lock,
              color: isUnlocked ? _accentGreen : Colors.grey.shade600,
              size: 22,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge.badgeName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isUnlocked ? "Đã đạt được" : "Chưa mở khóa",
                  style: TextStyle(
                    fontSize: 11,
                    color: isUnlocked ? _accentGreen : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeHorizontal(List<BadgeModel> badges) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isUnlocked = badge.awardedAt != null;

          return Container(
            width: 77,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isUnlocked
                  ? _accentGreen.withOpacity(0.12)
                  : const Color(0xFFF1F1F1),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isUnlocked ? Icons.emoji_events : Icons.lock,
                  size: 18,
                  color: isUnlocked ? _accentGreen : Colors.grey.shade500,
                ),
                const SizedBox(height: 4),
                Text(
                  badge.badgeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isUnlocked ? _textDark : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyBadge() {
    return _buildSectionContainer(
      title: 'Huy hiệu thành tích',
      child: Column(
        children: [
          const SizedBox(height: 12),
          Icon(Icons.emoji_events, size: 36, color: _accentGreen),
          const SizedBox(height: 6),
          Text(
            "Chưa có huy hiệu nào",
            style: TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(List<ActivityModel> activities) {
    if (activities.isEmpty) {
      return _buildSectionContainer(
        title: 'Hoạt động gần đây',
        onViewAll: null,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _accentGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.event_note,
                    color: _primaryGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Chưa có hoạt động',
                  style: TextStyle(
                    color: _textMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final latestActivities = List<ActivityModel>.from(activities)
      ..sort(
        (a, b) =>
            _parseDateTime(b.createdAt).compareTo(_parseDateTime(a.createdAt)),
      );

    return _buildSectionContainer(
      title: 'Hoạt động gần đây',
      onViewAll: () => Navigator.pushNamed(context, '/activity_history'),
      child: Column(
        children: latestActivities.take(3).map((activity) {
          final isGain = activity.points >= 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isGain
                    ? const Color(0xFFF0FAF5)
                    : const Color(0xFFFFF5F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isGain
                      ? const Color(0xFFD4EFE4)
                      : const Color(0xFFFFDFD6),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isGain
                          ? _accentGreen.withOpacity(0.2)
                          : const Color(0xFFD85B39).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isGain ? Icons.trending_up : Icons.trending_down,
                      color: isGain ? _accentGreen : const Color(0xFFD85B39),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${_formatDate(activity.createdAt)} • ${_timeAgo(activity.createdAt)}',
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isGain
                          ? _accentGreen.withOpacity(0.15)
                          : const Color(0xFFD85B39).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${isGain ? '+' : ''}${activity.points}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isGain ? _accentGreen : const Color(0xFFD85B39),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
    VoidCallback? onViewAll,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textDark,
                    letterSpacing: 0.3,
                  ),
                ),
                if (onViewAll != null)
                  GestureDetector(
                    onTap: onViewAll,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 4.0,
                        horizontal: 8.0,
                      ),
                      child: Text(
                        'Xem tất cả >',
                        style: TextStyle(
                          color: _accentGreen,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildRankingButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_primaryGreen, _accentGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _primaryGreen.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pushNamed(context, '/ranking');
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.emoji_events, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Text(
                  'Xem bảng xếp hạng',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(String? avatarUrl) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: _accentGreen.withOpacity(0.3), width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarUrl == null
            ? Container(
                color: const Color(0xFFF1F6F3),
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              )
            : Image.network(
                avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF1F6F3),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
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

  DateTime _parseDateTime(String dateString) {
    try {
      return DateTime.parse(dateString);
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  String? _resolveAvatarUrl(String rawUrl) {
    final value = rawUrl.trim();
    if (value.isEmpty) return null;
    if (value.startsWith('http')) return value;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? '';
    if (baseUrl.isEmpty) return value;

    if (value.startsWith('/')) {
      return '$baseUrl$value';
    }

    return '$baseUrl/$value';
  }
}
