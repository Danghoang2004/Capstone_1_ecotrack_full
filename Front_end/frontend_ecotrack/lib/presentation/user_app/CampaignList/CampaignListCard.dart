import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignRepository.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/data/models/CampaignModel.dart'; 
import 'package:frontend_ecotrack/presentation/user_app/CampaignList/CampaignDetailScreen.dart';

// Đổi từ StatelessWidget sang StatefulWidget để quản lý trạng thái nút bấm
class CampaignListCard extends StatefulWidget {
  final CampaignModel campaign; 
  final void Function(int campaignId, int participants)? onJoined;
  
  const CampaignListCard({
    super.key,
    required this.campaign,
    this.onJoined,
  });

  @override
  State<CampaignListCard> createState() => _CampaignListCardState();
}

class _CampaignListCardState extends State<CampaignListCard> {
  late final CampaignRepository _repo;

  bool _isLoading = false;
  late bool _isJoined;
  late int _participants;

  @override
  void initState() {
    super.initState();
    _repo = CampaignRepository(
      ApiClient(storage: const FlutterSecureStorage()),
    );
    _isJoined = widget.campaign.joined;
    _participants = widget.campaign.participants;
  }

  @override
  void didUpdateWidget(covariant CampaignListCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.campaign.id != widget.campaign.id) {
      _isJoined = widget.campaign.joined;
      _participants = widget.campaign.participants;
      return;
    }

    if (!_isLoading) {
      _isJoined = widget.campaign.joined;
      _participants = widget.campaign.participants;
    }
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
                  child: const Icon(Icons.check, color: Colors.white, size: 40),
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
                    icon: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 20,
                    ),
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

  // --- HÀM XỬ LÝ KHI BẤM NÚT THAM GIA ---
  Future<void> _handleJoin() async {
    setState(() {
      _isLoading = true; // Bật vòng xoay loading
    });

    try {
      await _repo.joinCampaign(widget.campaign.id);

      if (!mounted) return;
      setState(() {
        _isLoading = false; // Tắt loading
        _isJoined = true;   // Cập nhật trạng thái thành Đã tham gia
        _participants += 1;
      });

      widget.onJoined?.call(widget.campaign.id, _participants);

      // Hiện popup
      _showSuccessDialog(context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception:", "").trim()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dùng widget.campaign vì đang ở trong State class
    final campaign = widget.campaign;

    int fakeMaxParticipants = _participants == 0 ? 1000 : _participants + 500;
    
    double progressValue = (fakeMaxParticipants > 0) 
      ? (_participants / fakeMaxParticipants) 
        : 0.0;
    if (progressValue > 1.0) progressValue = 1.0;

    // --- LOGIC XÁC ĐỊNH MÀU VÀ CHỮ CHO NÚT BẤM ---
    String buttonText = "Tham gia chiến dịch";
    Color buttonColor = const Color(0xFF2E7D32);

    if (_isJoined) {
      buttonText = "Đã tham gia";
      buttonColor = Colors.grey; // Đổi sang xám khi đã tham gia
    } else if (_isLoading) {
      buttonText = "Đang xử lý...";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => _navigateToDetail(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 8,
                          child: Image.network(
                            campaign.imageUrl,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: const Color(0xFFF4FBF8),
                              child: const Icon(
                                Icons.image_not_supported_outlined,
                                size: 50,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            campaign.daysRemaining > 0
                                ? "${campaign.daysRemaining} ngày còn lại"
                                : "Đã kết thúc",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2D4F1E),
                                ),
                              ),
                            ),
                            Icon(
                              Icons.eco,
                              color: Colors.green.shade600,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildProgress(progressValue, fakeMaxParticipants),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.people_alt,
                                  size: 18,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${_participants} người", 
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),

                            // --- NÚT BẤM CÓ TRẠNG THÁI ---
                            ElevatedButton(
                              // Nếu đã tham gia hoặc đang loading thì khóa nút (trả về null)
                              onPressed: (_isJoined || _isLoading)
                                  ? null
                                  : _handleJoin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                disabledBackgroundColor: buttonColor
                                    .withOpacity(0.7), // Màu xám khi khóa
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      buttonText,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgress(double progressValue, int maxParticipants) {
    int percent = (progressValue * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.group_outlined,
                  size: 18,
                  color: Colors.green.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  "$maxParticipants người",
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade800),
                ),
              ],
            ),
            Text(
              "$percent%",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progressValue,
            backgroundColor: Colors.green.shade100.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  void _navigateToDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CampaignDetailScreen(
          campaignId: widget.campaign.id,
          initialJoined: _isJoined,
          initialParticipantCount: _participants,
        ), 
      ),
    );
  }
}
