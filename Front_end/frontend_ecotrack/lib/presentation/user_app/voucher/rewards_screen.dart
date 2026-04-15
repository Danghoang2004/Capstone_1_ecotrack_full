import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/voucher/MyCouponsScreen.dart';

const Color primaryGreen = Color.fromARGB(255, 62, 186, 112);

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  late final ApiClient apiClient;
  late final VoucherApi api;

  final storage = const FlutterSecureStorage();
  final UserService _userService = UserService();

  int? _currentUserId;
  int _userPoints = 0;

  List<RewardItem> _allRewards = [];
  List<RewardItem> _displayRewards = [];
  String _selectedCategory = 'ALL';
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(storage: storage);
    api = VoucherApi(apiClient);
    _initData();
  }

  Future<void> _initData() async {
    try {
      final profile = await _userService.getProfileView();
      if (mounted) {
        setState(() {
          _currentUserId = profile.userId;
          _userPoints = profile.points;
        });
      }
      await _loadRewards();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Lỗi tải dữ liệu: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _loadUserPoints() async {
    try {
      final profile = await _userService.getProfileView();
      if (mounted) {
        setState(() {
          _currentUserId = profile.userId;
          _userPoints = profile.points;
        });
      }
    } catch (e) {
      debugPrint("Lỗi load điểm: $e");
    }
  }

  Future<void> _loadRewards() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final list = await api.fetchRewards();
      if (mounted) {
        setState(() {
          _allRewards = list;
          _applyFilter();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
      _applyFilter();
    });
  }

  void _applyFilter() {
    if (_selectedCategory == 'ALL') {
      _displayRewards = List.from(_allRewards);
    } else {
      _displayRewards = _allRewards
          .where((r) => r.category == _selectedCategory)
          .toList();
    }
  }

  String _formatRedeemError(Object error) {
    final text = error.toString();
    final cleaned = text
        .replaceFirst(RegExp(r'^Exception:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^Error:\s*', caseSensitive: false), '')
        .replaceFirst(RegExp(r'^redeem failed:\s*', caseSensitive: false), '')
        .trim();

    if (cleaned.isEmpty) {
      return 'Không đổi được voucher. Vui lòng thử lại.';
    }

    return cleaned;
  }

  Future<void> _showMessageDialog({
    required String title,
    required String message,
    required Color accentColor,
    required IconData icon,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF8FCF9),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          title: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              height: 1.35,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text(
                  'Đóng',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Transform.translate(
          offset: Offset(-80, 0),
          child: Text(
            'Đổi thưởng',
            style: TextStyle(
              color: Colors.black,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        actions: [
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.redeem_outlined,
                  size: 16,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                const SizedBox(width: 4),
                Text(
                  '$_userPoints điểm',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color.fromARGB(255, 255, 255, 255),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.black),
            tooltip: 'Voucher của tôi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyCouponsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 1),
          _CategoryFilterRow(
            selectedCategory: _selectedCategory,
            onChanged: _onCategoryChanged,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text('Lỗi tải voucher: $_error'));
    }
    if (_displayRewards.isEmpty) {
      return const Center(child: Text('Chưa có voucher khả dụng'));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
      itemCount: _displayRewards.length,
      itemBuilder: (context, index) {
        final r = _displayRewards[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: RewardCard(
            tagText: r.tagText,
            tagColor: r.tagColor,
            imageUrl: r.imageUrl, // Sử dụng imageUrl thay vì icon
            title: r.title,
            subtitle: r.subtitle,
            partnerName: r.partnerName,
            distance: r.distance,
            expiry: r.expiry,
            priceText: r.priceText,
            originalPriceText: r.originalPriceText,
            pointsText: r.pointsText,
            rating: r.rating,
            showRating: r.showRating,
            onRedeem: () async {
              try {
                if (_currentUserId == null) return;
                await api.redeemVoucher(r.voucherId, _currentUserId!);
                if (!mounted) return;
                _loadRewards();
                _loadUserPoints();
                await _showMessageDialog(
                  title: 'Đổi thành công',
                  message:
                      'Voucher đã được đổi thành công. Bạn có thể kiểm tra lại trong mục voucher của tôi.',
                  accentColor: const Color(0xFF2E7D32),
                  icon: Icons.check_circle,
                );
              } catch (e) {
                if (!mounted) return;
                await _showMessageDialog(
                  title: 'Chưa thể đổi voucher',
                  message: _formatRedeemError(e),
                  accentColor: Colors.redAccent,
                  icon: Icons.error_outline,
                );
              }
            },
          ),
        );
      },
    );
  }
}

// ... _CategoryFilterRow và _CategoryFixedItem giữ nguyên ...
class _CategoryFilterRow extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onChanged;

  const _CategoryFilterRow({
    required this.selectedCategory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      {'name': 'Tất cả', 'icon': Icons.dashboard_outlined, 'key': 'ALL'},
      {'name': 'Ăn uống', 'icon': Icons.restaurant, 'key': 'FOOD'},
      {
        'name': 'Mua sắm',
        'icon': Icons.shopping_bag_outlined,
        'key': 'SHOPPING',
      },
      {'name': 'Di chuyển', 'icon': Icons.directions_car, 'key': 'TRAVEL'},
      {'name': 'Dịch vụ', 'icon': Icons.spa_outlined, 'key': 'SERVICE'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(5, 3, 5, 1),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: items.map((item) {
            final key = item['key'] as String;
            final selected = key == selectedCategory;
            return Expanded(
              child: _CategoryFixedItem(
                name: item['name'] as String,
                icon: item['icon'] as IconData,
                selected: selected,
                onTap: () => onChanged(key),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _CategoryFixedItem extends StatelessWidget {
  final String name;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryFixedItem({
    required this.name,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color textColor = selected ? primaryGreen : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: textColor),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- MODEL & CARD (Sửa logic ảnh) ---

class RewardItem {
  final int voucherId;
  final String tagText;
  final Color tagColor;
  final String? imageUrl; // Dùng String cho URL ảnh
  final String title;
  final String subtitle;
  final String partnerName;
  final String distance;
  final String expiry;
  final String priceText;
  final String? originalPriceText;
  final String pointsText;
  final double rating;
  final bool showRating;
  final String category;

  const RewardItem({
    required this.voucherId,
    required this.tagText,
    required this.tagColor,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.partnerName,
    required this.distance,
    required this.expiry,
    required this.priceText,
    this.originalPriceText,
    required this.pointsText,
    required this.rating,
    required this.showRating,
    required this.category,
  });

  // Sửa: Nhận thêm ApiClient để build URL ảnh đầy đủ
  factory RewardItem.fromJson(Map<String, dynamic> json, ApiClient api) {
    final int id = json['voucherId'] ?? 0;
    final String title = (json['title'] ?? '') as String;
    String category = (json['category'] ?? 'SHOPPING').toString().toUpperCase();

    // Dùng hàm buildImageUrl từ ApiClient
    String? imgUrl = api.buildImageUrl(json['imageUrl']);

    return RewardItem(
      voucherId: id,
      tagText: 'Ưu đãi',
      tagColor: primaryGreen,
      imageUrl: imgUrl, // Gán URL ảnh
      title: title,
      subtitle: json['description'] ?? '',
      partnerName: json['partnerName'] ?? 'Eco Partner',
      distance: 'Online voucher',
      expiry: json['expiryDate']?.toString() ?? '',
      priceText: json['value']?.toString() ?? '',
      originalPriceText: null,
      pointsText: '${json['pointsRequired'] ?? 0} điểm',
      rating: 4.5,
      showRating: false,
      category: category,
    );
  }
}

class RewardCard extends StatelessWidget {
  final String tagText;
  final Color tagColor;
  final String? imageUrl;
  final String title;
  final String subtitle;
  final String partnerName;
  final String distance;
  final String expiry;
  final String priceText;
  final String? originalPriceText;
  final String pointsText;
  final double rating;
  final bool showRating;
  final VoidCallback onRedeem;

  const RewardCard({
    super.key,
    required this.tagText,
    required this.tagColor,
    this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.partnerName,
    required this.distance,
    required this.expiry,
    required this.priceText,
    this.originalPriceText,
    required this.pointsText,
    required this.rating,
    required this.showRating,
    required this.onRedeem,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15), // Bo góc to hơn giống thiết kế
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.06), // Đổ bóng nhẹ nhàng hơn
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Khung ảnh Logo bên trái (có viền bo tròn)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            padding: const EdgeInsets.all(1),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.storefront,
                          color: Colors.green.shade300,
                          size: 10,
                        );
                      },
                    )
                  : Icon(
                      Icons.storefront,
                      color: Colors.green.shade300,
                      size: 30,
                    ),
            ),
          ),
          const SizedBox(width: 4),

          // 2. Nội dung bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tiêu đề Voucher
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 1),

                // Mô tả (Subtitle)
                Text(
                  subtitle,
                  maxLines: 2, // Để 1 dòng cho gọn giống thiết kế
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 5),

                // Hàng thông tin 1: Partner & Rating
                Row(
                  children: [
                    Icon(
                      Icons.shopping_bag_outlined,
                      size: 14,
                      color: const Color(0xFF2E7D32),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        partnerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 2),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 81),
                  ],
                ),
                const SizedBox(height: 4),

                // Hàng thông tin 2: Địa điểm & Thời gian (Icon màu cam)
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: Colors.orange.shade400,
                    ),
                    const SizedBox(width: 1),
                    Text(
                      distance,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: Colors.orange.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Đến $expiry',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Hàng cuối: Điểm số & Nút Đổi ngay
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Cụm điểm số (Icon mầm cây)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.eco_outlined, // Icon hình cái lá/mầm cây
                          size: 20,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          pointsText,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),

                    // Nút bấm Đổi ngay
                    SizedBox(
                      height: 29,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Bo góc vừa phải giống hình
                          ),
                          elevation: 0,
                        ),
                        onPressed: onRedeem,
                        child: const Text(
                          'Đổi ngay',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
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
    );
  }
}
