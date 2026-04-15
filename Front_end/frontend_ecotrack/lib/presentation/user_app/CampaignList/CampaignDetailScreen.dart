import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignDetailModel.dart';

class CampaignDetailScreen extends StatefulWidget {
  final int campaignId;
  final bool initialJoined;
  final int? initialParticipantCount;

  const CampaignDetailScreen({
    super.key,
    required this.campaignId,
    this.initialJoined = false,
    this.initialParticipantCount,
  });

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> {
  late CampaignRepository _repo;
  late Future<CampaignDetailModel> _campaignFuture;
  bool _isJoining = false;
  late bool _joinedOverride;
  int? _participantOverride;

  @override
  void initState() {
    super.initState();
    _repo = CampaignRepository(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _joinedOverride = widget.initialJoined;
    _participantOverride = widget.initialParticipantCount;
    _loadCampaign();
  }

  // --- GỌI API THẬT ĐỂ LẤY CHI TIẾT ---
  void _loadCampaign() {
    setState(() {
      _campaignFuture = _repo.fetchCampaignDetail(widget.campaignId);
    });
  }

  // --- HÀM THIẾT KẾ POPUP THÀNH CÔNG ---
  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2E7D32),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Đăng ký thành công!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Cảm ơn bạn đã tham gia chiến dịch. Hãy cùng EcoTrack tạo nên những giá trị xanh nhé!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Đóng popup
                    },
                    icon: const Icon(Icons.check, color: Colors.white, size: 20),
                    label: const Text(
                      "Tuyệt vời",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- GỌI API THẬT ĐỂ THAM GIA CHIẾN DỊCH ---
  Future<void> _handleJoinCampaign(int currentParticipantCount) async {
    setState(() {
      _isJoining = true;
    });

    try {
      // GỌI API LÊN BACKEND
      await _repo.joinCampaign(widget.campaignId);

      if (mounted) {
        setState(() {
          _joinedOverride = true;
          _participantOverride = currentParticipantCount + 1;
        });

        // Hiện Popup thành công
        _showSuccessDialog(context);
        
        // Gọi lại API load chi tiết để cập nhật số người và trạng thái nút bấm
        _loadCampaign(); 
      }
    } catch (e) {
      if (mounted) {
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
        backgroundColor: const Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Chi tiết chiến dịch",
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<CampaignDetailModel>(
        future: _campaignFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
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
                    child: const Text("Thử lại", style: TextStyle(color: Colors.green)),
                  ),
                ],
              ),
            );
          }

          final c = snapshot.data!;
          final effectiveParticipants = _participantOverride != null &&
                  _participantOverride! > c.participantCount
              ? _participantOverride!
              : c.participantCount;
          final effectiveJoined = c.joined || _joinedOverride;
          final progress = c.maxParticipants > 0
              ? (effectiveParticipants / c.maxParticipants).clamp(0.0, 1.0)
              : 0.0;

          return Stack(
            children: [
              _body(context, c, progress, effectiveParticipants),
              _joinButton(c, effectiveJoined, effectiveParticipants),
            ],
          );
        },
      ),
    );
  }

  Widget _body(
    BuildContext context,
    CampaignDetailModel c,
    double progress,
    int effectiveParticipants,
  ) {
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
                  Container(color: Colors.grey.shade300, child: const Icon(Icons.image, size: 50, color: Colors.grey)),
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
                    Text("EcoVietnam tổ chức", style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
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
                _participants(effectiveParticipants, c.maxParticipants, progress),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
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
                        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.grey.shade800),
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

  Widget _joinButton(
    CampaignDetailModel c,
    bool effectiveJoined,
    int effectiveParticipants,
  ) {
    final bool isFull = effectiveParticipants >= c.maxParticipants;
    final bool canJoin = !effectiveJoined && !isFull && !_isJoining;

    String buttonText = "Tham gia chiến dịch";
    Color buttonColor = const Color(0xFF2E7D32); 

    if (effectiveJoined) {
      buttonText = "Đã tham gia";
      buttonColor = Colors.grey;
    } else if (isFull) {
      buttonText = "Đã đủ số lượng";
      buttonColor = Colors.orange;
    } else if (_isJoining) {
      buttonText = "Đang xử lý...";
    }

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: SizedBox(
        height: 50,
        child: ElevatedButton(
            onPressed: canJoin
              ? () => _handleJoinCampaign(effectiveParticipants)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonColor,
            disabledBackgroundColor: buttonColor.withOpacity(0.6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25), 
            ),
            elevation: effectiveJoined ? 0 : 4,
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
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
        Text("$value", style: TextStyle(color: Colors.grey.shade800, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _dateRange(String startDate, String endDate) {
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 18, color: Colors.grey[700]),
        const SizedBox(width: 4),
        Text(
          endDate, 
          style: TextStyle(fontSize: 14, color: Colors.grey.shade800, fontWeight: FontWeight.w500),
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
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _participants(int current, int max, double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tiến độ tham gia",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.green.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            minHeight: 8,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("$current / $max người đã đăng ký", style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}