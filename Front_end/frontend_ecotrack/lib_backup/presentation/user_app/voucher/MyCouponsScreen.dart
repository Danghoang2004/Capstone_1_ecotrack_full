import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
// Đảm bảo UserCouponItem của em có các trường: id, title, imageUrl, partnerName, expiryDate, status
import 'package:frontend_ecotrack/data/models/UserCouponItem.dart';
import '../../../core/services/UserCouponApi.dart';

// Class phụ trợ để lưu trữ Voucher đã gộp (Voucher + Số lượng)
class GroupedCoupon {
  final UserCouponItem item;
  final int quantity;

  GroupedCoupon({required this.item, required this.quantity});
}

class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  late final ApiClient apiClient;
  late final UserCouponApi api;

  // Thay vì List<UserCouponItem>, ta dùng List<GroupedCoupon>
  List<GroupedCoupon> groupedCoupons = [];
  bool _loading = true;
  String? _error;

  // Bảng màu Eco Theme (Em có thể tách ra file constants riêng)
  final Color primaryGreen = const Color(0xFF2E7D32); // Xanh rừng
  final Color lightGreenBg = const Color(0xFFF1F8E9); // Xanh nhạt nền
  final Color accentOrange = const Color(0xFFFF8F00); // Màu nhấn cho HSD

  @override
  void initState() {
    super.initState();
    apiClient = ApiClient(storage: const FlutterSecureStorage());
    api = UserCouponApi(apiClient);
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rawList = await api.fetchMyCoupons();
      // Logic xử lý gom nhóm voucher
      final processedList = _processCoupons(rawList);

      setState(() {
        groupedCoupons = processedList;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // LOGIC: Hàm gom nhóm các voucher giống nhau
  List<GroupedCoupon> _processCoupons(List<UserCouponItem> list) {
    if (list.isEmpty) return [];

    // Map để đếm số lượng: Key là ID (hoặc Title nếu không có ID), Value là số lượng
    Map<String, int> counts = {};
    // Map để lưu giữ object gốc đại diện
    Map<String, UserCouponItem> uniqueItems = {};

    for (var item in list) {
      // Giả sử dùng title làm key nếu không có id. Tốt nhất nên dùng item.id
      // final key = item.id;
      final key = item.title;

      if (!counts.containsKey(key)) {
        counts[key] = 1;
        uniqueItems[key] = item;
      } else {
        counts[key] = counts[key]! + 1;
      }
    }

    // Chuyển đổi Map trở lại thành List<GroupedCoupon>
    return uniqueItems.entries.map((entry) {
      return GroupedCoupon(item: entry.value, quantity: counts[entry.key]!);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGreenBg, // Nền sáng nhẹ nhàng
      appBar: AppBar(
        backgroundColor: primaryGreen,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 25),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Kho Voucher Của Tôi",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: primaryGreen));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 10),
            Text(
              'Có lỗi xảy ra: $_error',
              style: const TextStyle(color: Colors.grey),
            ),
            TextButton(onPressed: _loadCoupons, child: const Text("Thử lại")),
          ],
        ),
      );
    }

    if (groupedCoupons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.eco_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa có voucher nào',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groupedCoupons.length,
      separatorBuilder: (c, i) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return _EcoCouponCard(groupedItem: groupedCoupons[index]);
      },
    );
  }
}

// Widget Card được thiết kế lại giống RewardCard
class _EcoCouponCard extends StatelessWidget {
  final GroupedCoupon groupedItem;

  const _EcoCouponCard({required this.groupedItem});

  @override
  Widget build(BuildContext context) {
    final item = groupedItem.item;
    // Màu chủ đạo lấy theo RewardScreen để đồng bộ
    const Color primaryGreen = Color(0xFF06923E);

    // Xác định trạng thái để hiển thị màu sắc và text
    Color statusColor;
    String statusText;
    if (item.isUsed) {
      statusColor = Colors.grey;
      statusText = "Đã dùng";
    } else if (item.isExpired) {
      statusColor = Colors.red;
      statusText = "Hết hạn";
    } else {
      statusColor = primaryGreen;
      statusText = "Khả dụng";
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6), // Bo góc giống RewardCard
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
          // 1. Khung ảnh vuông bên trái (Giống RewardCard)
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 60,
              height: 60,
              color: statusColor.withOpacity(0.1),
              child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                  ? Image.network(
                      item.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.confirmation_number_outlined,
                          color: statusColor,
                        );
                      },
                    )
                  : Icon(Icons.local_activity, size: 30, color: statusColor),
            ),
          ),
          const SizedBox(width: 8),

          // 2. Nội dung bên phải
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag trạng thái + Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusText, // Hiển thị: Khả dụng/Đã dùng...
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
                        item.title,
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

                const SizedBox(height: 3),

                // Tên đối tác (Partner Name)
                Text(
                  item.partnerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                // Ngày hết hạn (Thay thế vị trí Distance của RewardCard)
                Row(
                  children: [
                    Icon(
                      Icons.access_time, // Icon đồng hồ
                      size: 11,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'HSD: ${item.expiryDate}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Footer: Nút "Sử dụng" giả lập hoặc Badge số lượng
                Row(
                  children: [
                    // Text hiển thị loại voucher (Online/Offline)
                    const Text(
                      "Voucher điện tử",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryGreen,
                      ),
                    ),

                    const Spacer(),

                    // --- LOGIC HIỂN THỊ SỐ LƯỢNG ---
                    // Thay thế nút "Đổi ngay" bằng chỉ số số lượng
                    Container(
                      height: 24, // Chiều cao nhỏ gọn
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: primaryGreen, width: 1),
                        boxShadow: [
                          BoxShadow(
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                            color: primaryGreen.withOpacity(0.2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Icon(Icons.layers, size: 12, color: primaryGreen),
                          const SizedBox(width: 4),
                          Text(
                            'x${groupedItem.quantity}', // Số lượng voucher
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: primaryGreen,
                            ),
                          ),
                        ],
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

  Widget _buildStatusBadge(UserCouponItem item) {
    String text;
    Color color;
    Color bg;

    if (item.isUsed) {
      text = "Đã dùng";
      color = Colors.grey;
      bg = Colors.grey[100]!;
    } else if (item.isExpired) {
      text = "Hết hạn";
      color = Colors.red;
      bg = Colors.red[50]!;
    } else {
      text = "Có sẵn";
      color = Colors.green;
      bg = Colors.green[50]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5), width: 0.5),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
