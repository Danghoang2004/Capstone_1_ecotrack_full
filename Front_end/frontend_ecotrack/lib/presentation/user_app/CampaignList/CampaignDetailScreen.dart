import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignDetailModel.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;

  const CampaignDetailScreen({super.key, required this.campaignId});

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
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
            content: Text("Tham gia chiến dịch thành công!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        _loadCampaign(); // Refresh data
      }
    } catch (e) {
      if (mounted) {
        // Backend trả về message lỗi, hiển thị cho user
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception:", "").trim()),
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
      backgroundColor: const Color(0xFFF6F7F6),
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: const Text(
          "Chi tiết chiến dịch",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<CampaignDetailModel>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Không thể tải chiến dịch"),
                  TextButton(
                    onPressed: _loadCampaign,
                    child: const Text("Thử lại"),
                  ),
                ],
              ),
            );
          }

          final c = snapshot.data!;
          final progress = c.maxParticipants > 0
              ? (c.participantCount / c.maxParticipants).clamp(0.0, 1.0)
              : 0.0;

          return Stack(children: [_body(context, c, progress), _joinButton(c)]);
        },
      ),
    );
  }

  Widget _body(BuildContext context, CampaignDetailModel c, double progress) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 90),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              c.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade300),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: const [
                    Icon(Icons.verified, color: Colors.green, size: 16),
                    SizedBox(width: 6),
                    Text("EcoVietnam tổ chức"),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _iconText(Icons.favorite_border, c.likeCount),
                    const SizedBox(width: 16),
                    _iconText(Icons.chat_bubble_outline, c.commentCount),
                    const SizedBox(width: 16),
                    _dateRange(c.startDate, c.endDate),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(title: "Địa điểm", value: c.location),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoBox(title: "Thời gian", value: c.timeRange),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _participants(c.participantCount, c.maxParticipants, progress),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Mô tả chiến dịch",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        c.description,
                        style: const TextStyle(fontSize: 14, height: 1.5),
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

  Widget _joinButton(CampaignDetailModel c) {
    final bool isFull = c.participantCount >= c.maxParticipants;
    final bool canJoin = !c.joined && !isFull && !_isJoining;

    String buttonText = "Tham gia chiến dịch";
    Color buttonColor = Colors.green;

    if (c.joined) {
      buttonText = "Đã tham gia";
      buttonColor = Colors.grey;
    } else if (isFull) {
      buttonText = "Đã đủ số lượng";
      buttonColor = Colors.redAccent;
    } else if (_isJoining) {
      buttonText = "Đang xử lý...";
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: 48,
        child: ElevatedButton(
          onPressed: canJoin ? _handleJoinCampaign : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: buttonColor.withOpacity(0.7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isJoining
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, int value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text("$value"),
      ],
    );
  }

  Widget _dateRange(String startDate, String endDate) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          endDate, // Hiển thị ngày kết thúc hoặc logic tùy ý
          style: const TextStyle(fontSize: 14),
        ),
      ],
    );
  }

  Widget _infoBox({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _participants(int current, int max, double progress) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Người tham gia",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.green.shade100,
            color: Colors.green,
            minHeight: 6,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$current / $max người đã đăng ký"),
              Text("${(progress * 100).toStringAsFixed(0)}%"),
            ],
          ),
        ],
      ),
    );
  }
}
