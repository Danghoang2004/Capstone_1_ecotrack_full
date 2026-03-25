import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignDetailModel.dart';
import 'package:intl/intl.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  final String? initialImageUrl;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    this.initialImageUrl,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  static const Color _forestGreen = Color(0xFF0A4C3A);
  static const Color _leafGreen = Color(0xFF9AD94C);
  static const Color _softGreen = Color(0xFF89C6B3);
  static const Color _surfaceColor = Color(0xFFF7F8F5);
  static const Color _lineColor = Color(0xFFE2E6E1);
  static const Color _textPrimary = Color(0xFF1F2522);
  static const Color _textSecondary = Color(0xFF6F7772);

  late CampaignRepository _repo;
  late Future<CampaignDetailModel> _campaignFuture;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _repo = CampaignRepository(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _loadCampaign();
  }

  void _loadCampaign() {
    setState(() {
      _campaignFuture = _repo.fetchCampaignDetail(widget.campaignId);
    });
  }

  Future<void> _handleJoinCampaign() async {
    setState(() {
      _isJoining = true;
    });

    try {
      await _repo.joinCampaign(widget.campaignId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tham gia chiến dịch thành công!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadCampaign();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _forestGreen),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Eco Track',
          style: TextStyle(
            color: Color(0xFF2F7D32),
            fontSize: 28,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
          ),
        ),
      ),
      body: FutureBuilder<CampaignDetailModel>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 52,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Không thể tải chi tiết chiến dịch',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error ?? ''}'.trim(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: _textSecondary),
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _loadCampaign,
                      style: FilledButton.styleFrom(
                        backgroundColor: _forestGreen,
                      ),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            );
          }

          final c = snapshot.data!;
          final progress = c.maxParticipants > 0
              ? (c.participantCount / c.maxParticipants).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            children: [
              _body(context, c, progress),
              _joinButton(c),
            ],
          );
        },
      ),
    );
  }

  Widget _body(BuildContext context, CampaignDetailModel c, double progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 116),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 246,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _heroImage(_resolveHeroImageUrl(c)),
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xD0003B2F),
                        Color(0xEB064836),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                const _HeroDecoration(),
              ],
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -28),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBadge(c),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _buildScheduleLabel(c),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      c.title,
                      style: const TextStyle(
                        fontSize: 22,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Divider(height: 1, color: _lineColor),
                    const SizedBox(height: 18),
                    _sectionTitle('Mô tả chi tiết'),
                    const SizedBox(height: 10),
                    Text(
                      c.description.trim().isEmpty
                          ? 'Chưa có mô tả chi tiết cho chiến dịch này.'
                          : c.description,
                      style: const TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(height: 1, color: _lineColor),
                    const SizedBox(height: 18),
                    _sectionTitle('Vị trí'),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: Color(0xFFE14C42),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.location,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.5,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _infoPanel(
                      child: Column(
                        children: [
                          _infoRow(
                            Icons.schedule_rounded,
                            'Thời gian',
                            c.timeRange,
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.groups_rounded,
                            'Người tham gia',
                            '${c.participantCount}/${c.maxParticipants}',
                          ),
                          const SizedBox(height: 12),
                          _infoRow(
                            Icons.workspace_premium_rounded,
                            'Điểm thưởng',
                            '${c.rewardPoints} điểm',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _participantsCard(c, progress),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _metaChip(
                          icon: Icons.favorite_border_rounded,
                          label: '${c.likeCount} lượt quan tâm',
                        ),
                        _metaChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: '${c.commentCount} bình luận',
                        ),
                        _metaChip(
                          icon: c.joined
                              ? Icons.verified_rounded
                              : Icons.eco_rounded,
                          label: c.joined ? 'Bạn đã tham gia' : 'Mở đăng ký',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroImage(String imageUrl) {
    if (imageUrl.trim().isEmpty) {
      return _heroFallback();
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _heroFallback(),
    );
  }

  String _resolveHeroImageUrl(CampaignDetailModel c) {
    final detailImageUrl = c.imageUrl.trim();
    if (detailImageUrl.isNotEmpty) {
      return detailImageUrl;
    }

    return widget.initialImageUrl?.trim() ?? '';
  }

  Widget _heroFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFDDE5DB),
            Color(0xFFEAF0E7),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -46,
            right: -28,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.34),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            top: 18,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF4F7F3).withOpacity(0.92),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _fallbackField(
                    icon: Icons.image_outlined,
                    label: 'Ảnh chiến dịch đang cập nhật',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Cover mới',
                        style: TextStyle(
                          color: Color(0xFFE56A2E),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _fallbackField(
                    icon: Icons.palette_outlined,
                    label: 'Nền đang dùng giao diện mặc định',
                  ),
                  const SizedBox(height: 12),
                  _fallbackField(
                    icon: Icons.eco_outlined,
                    label: 'Eco Track sẽ hiển thị ảnh tại đây',
                  ),
                ],
              ),
            ),
          ),
          const _HeroDecoration(),
          Positioned(
            left: 22,
            right: 22,
            bottom: 34,
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F6F3E),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Eco Track',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF2C3E2F),
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Fallback cover theo phong cách thẻ giao diện',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF7A8B7F),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackField({
    required IconData icon,
    required String label,
    Widget? trailing,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEE7),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF8C9A90),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF64756A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 10),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _joinButton(CampaignDetailModel c) {
    final bool isFull = c.participantCount >= c.maxParticipants;
    final bool canJoin = !c.joined && !isFull && !_isJoining;

    String buttonText = 'Tham gia chiến dịch';
    Color buttonColor = _forestGreen;

    if (c.joined) {
      buttonText = 'Đã tham gia';
      buttonColor = Colors.grey;
    } else if (isFull) {
      buttonText = 'Đã đủ số lượng';
      buttonColor = Colors.redAccent;
    } else if (_isJoining) {
      buttonText = 'Đang xử lý...';
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: _forestGreen.withOpacity(0.18),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: canJoin ? _handleJoinCampaign : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                disabledBackgroundColor: buttonColor.withOpacity(0.8),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isJoining
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.4,
                      ),
                    )
                  : Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(CampaignDetailModel c) {
    final _StatusPresentation status = _resolveStatus(c);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: status.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            status.label,
            style: TextStyle(
              color: status.foreground,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            status.icon,
            size: 14,
            color: status.foreground,
          ),
        ],
      ),
    );
  }

  Widget _participantsCard(CampaignDetailModel c, double progress) {
    return _infoPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ tham gia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFDDEADF),
              color: _leafGreen,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                '${c.participantCount} người đã đăng ký',
                style: const TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: _forestGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD7DDD6)),
      ),
      child: child,
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _textSecondary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7F4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E6E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: _forestGreen),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: _textPrimary,
      ),
    );
  }

  String _buildScheduleLabel(CampaignDetailModel c) {
    final String dateText = _formatDate(c.startDate);
    final String timeText = c.timeRange.trim();

    if (dateText.isEmpty && timeText.isEmpty) {
      return '';
    }
    if (dateText.isEmpty) {
      return timeText;
    }
    if (timeText.isEmpty) {
      return dateText;
    }
    return '$dateText $timeText';
  }

  String _formatDate(String raw) {
    try {
      final DateTime date = DateTime.parse(raw);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (_) {
      return raw;
    }
  }

  _StatusPresentation _resolveStatus(CampaignDetailModel c) {
    final DateTime now = DateTime.now();
    DateTime? start;
    DateTime? end;

    try {
      start = DateTime.parse(c.startDate);
    } catch (_) {
      start = null;
    }

    try {
      end = DateTime.parse(c.endDate);
    } catch (_) {
      end = null;
    }

    if (c.joined) {
      return const _StatusPresentation(
        label: 'ĐÃ THAM GIA',
        icon: Icons.check_circle_rounded,
        background: Color(0xFFD8EEE2),
        foreground: Color(0xFF24714C),
      );
    }

    if (c.participantCount >= c.maxParticipants && c.maxParticipants > 0) {
      return const _StatusPresentation(
        label: 'ĐÃ ĐỦ CHỖ',
        icon: Icons.group_off_rounded,
        background: Color(0xFFF6DDD8),
        foreground: Color(0xFFB34A39),
      );
    }

    if (start != null && now.isBefore(start)) {
      return const _StatusPresentation(
        label: 'SẮP DIỄN RA',
        icon: Icons.schedule_rounded,
        background: Color(0xFFE5F0DB),
        foreground: Color(0xFF5C7C2F),
      );
    }

    if (end != null && now.isAfter(end)) {
      return const _StatusPresentation(
        label: 'ĐÃ KẾT THÚC',
        icon: Icons.event_busy_rounded,
        background: Color(0xFFE7EAEE),
        foreground: Color(0xFF6B7480),
      );
    }

    return const _StatusPresentation(
      label: 'ĐANG MỞ',
      icon: Icons.visibility_rounded,
      background: Color(0xFFB7DDD3),
      foreground: Color(0xFF1D6454),
    );
  }
}

class _StatusPresentation {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;

  const _StatusPresentation({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

class _HeroDecoration extends StatelessWidget {
  const _HeroDecoration();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: _CampaignDetailScreenState._softGreen.withOpacity(0.18),
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(300, 34),
              ),
            ),
          ),
        ),
        Positioned(
          left: -12,
          right: -12,
          bottom: 16,
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: const BorderRadius.vertical(
                top: Radius.elliptical(320, 28),
              ),
            ),
          ),
        ),
        const Center(child: _PlantIllustration()),
      ],
    );
  }
}

class _PlantIllustration extends StatelessWidget {
  const _PlantIllustration();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 108,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: _CampaignDetailScreenState._leafGreen.withOpacity(0.16),
              shape: BoxShape.circle,
            ),
          ),
          const Icon(
            Icons.eco_rounded,
            size: 46,
            color: _CampaignDetailScreenState._leafGreen,
          ),
          Positioned(
            bottom: 16,
            child: Container(
              width: 34,
              height: 4,
              decoration: BoxDecoration(
                color: _CampaignDetailScreenState._leafGreen.withOpacity(0.75),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
