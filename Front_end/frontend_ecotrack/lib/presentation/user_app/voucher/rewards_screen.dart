import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';

const Color primaryGreen = Color(0xFF06923E);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 0.1, right: 5),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: 4),
              const Text(
                'Đổi thưởng',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.redeem_outlined,
                      size: 16,
                      color: Colors.black,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_userPoints điểm',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 2),
          _CategoryFilterRow(
            selectedCategory: _selectedCategory,
            onChanged: _onCategoryChanged,
          ),
          Divider(height: 1, color: Colors.grey.shade300),
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đổi voucher thành công')),
                );
                _loadRewards();
                _loadUserPoints();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Không đổi được: $e')));
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
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: primaryGreen, width: 1.4),
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
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? primaryGreen.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                name,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
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
  final String? imageUrl; // Nhận URL ảnh
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
    this.imageUrl, // Nullable
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            blurRadius: 3,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Khung ảnh vuông bên trái
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: tagColor.withOpacity(0.1),
              child: (imageUrl != null && imageUrl!.isNotEmpty)
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.broken_image, color: tagColor);
                      },
                    )
                  : Icon(Icons.card_giftcard, size: 30, color: tagColor),
            ),
          ),
          const SizedBox(width: 8),

          // Nội dung bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: tagColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tagText,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),

                // Description
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),

                const SizedBox(height: 4),

                // Partner + Rating
                Row(
                  children: [
                    Text(
                      partnerName,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (showRating) ...[
                      const SizedBox(width: 3),
                      const Icon(Icons.star, color: Colors.amber, size: 11),
                      const SizedBox(width: 2),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 3),

                // Distance + Date
                Row(
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 11,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        distance,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 8),
                      ),
                    ),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 11,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text('Đến $expiry', style: const TextStyle(fontSize: 10)),
                  ],
                ),

                const SizedBox(height: 4),

                // Footer: Price + Points + Button
                Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          priceText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),
                        if (originalPriceText != null)
                          Text(
                            originalPriceText!,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.redeem_outlined,
                          size: 12,
                          color: primaryGreen,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          pointsText,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
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
