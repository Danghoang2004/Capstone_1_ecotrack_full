import 'package:flutter/material.dart';
import '../controllers/coupon_controller.dart';
import '../widgets/stat_card/stat_card.dart';
import '../widgets/coupon_list_header/coupon_list_header.dart';
import '../widgets/coupon_item/coupon_item.dart';
import '../widgets/create_coupon_dialog/create_coupon_dialog.dart';
import '../widgets/edit_coupon_dialog/edit_coupon_dialog.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  late final CouponController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CouponController();
    _controller.addListener(_onControllerUpdate);
    _controller.loadCoupons();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showCreateCouponDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CreateCouponDialog(
        onCreateCoupon: (data) async {
          final success = await _controller.createCoupon(data);
          if (success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tạo coupon thành công!'),
                  backgroundColor: Color(0xFF008000),
                ),
              );
            }
            return true;
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _controller.error ?? 'Có lỗi xảy ra khi tạo coupon',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }

  void _showEditCouponDialog(coupon) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EditCouponDialog(
        coupon: coupon,
        onUpdateCoupon: (data) async {
          if (coupon.couponId == null) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Không thể cập nhật coupon: thiếu ID'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }

          final success = await _controller.updateCoupon(
            coupon.couponId!,
            data,
          );
          if (success) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cập nhật coupon thành công!'),
                  backgroundColor: Color(0xFF008000),
                ),
              );
            }
            return true;
          } else {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _controller.error ?? 'Có lỗi xảy ra khi cập nhật coupon',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return false;
          }
        },
      ),
    );
  }

  void _showDeleteCouponDialog(coupon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Coupon'),
        content: Text('Bạn có chắc chắn muốn xóa coupon "${coupon.code}"? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);

              if (coupon.couponId == null) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Không thể xóa coupon: thiếu ID'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              final success = await _controller.deleteCoupon(coupon.couponId!);
              if (success) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Xóa coupon thành công!'),
                      backgroundColor: Color(0xFF008000),
                    ),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.error ?? 'Có lỗi xảy ra khi xóa coupon',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1000;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB), // Nền xám nhạt hiện đại
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION: THẺ THỐNG KÊ (STAT CARDS) ---
            Builder(
              builder: (context) {
                final stats = _controller.getStatistics();
                if (isMobile)
                  return Column(
                    children: [
                      StatCard(
                        title: 'Tổng Giá Trị Voucher',
                        value: stats['totalRevenue'] ?? '0₫',
                        change: 'Tổng giá trị voucher đã được đổi',
                        isPositive: true,
                        icon: Icons.card_giftcard,
                      ),
                      const SizedBox(height: 16),
                      StatCard(
                        title: 'Coupon Hoạt Động',
                        value: stats['activeCoupons'] ?? '0',
                        change: 'Coupon đang hoạt động',
                        isPositive: true,
                        icon: Icons.confirmation_number_outlined,
                      ),
                      const SizedBox(height: 16),
                      StatCard(
                        title: 'Lượt Sử Dụng Coupon',
                        value: stats['usageCount'] ?? '0',
                        change: 'Tổng lượt đã sử dụng',
                        isPositive: true,
                        icon: Icons.people_outline,
                      ),
                      const SizedBox(height: 16),
                      StatCard(
                        title: 'ROI',
                        value: stats['roi'] ?? '0%',
                        change: 'Return on Investment',
                        isPositive: true,
                        icon: Icons.trending_up,
                      ),
                    ],
                  );
                else
                  return Row(
                    children: [
                      Expanded(
                        child: StatCard(
                          title: 'Tổng Doanh Thu',
                          value: stats['totalRevenue'] ?? '0₫',
                          change: 'Từ các coupon đã sử dụng',
                          isPositive: true,
                          icon: Icons.attach_money,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StatCard(
                          title: 'Coupon Hoạt Động',
                          value: stats['activeCoupons'] ?? '0',
                          change: 'Coupon đang hoạt động',
                          isPositive: true,
                          icon: Icons.confirmation_number_outlined,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StatCard(
                          title: 'Lượt Sử Dụng Coupon',
                          value: stats['usageCount'] ?? '0',
                          change: 'Tổng lượt đã sử dụng',
                          isPositive: true,
                          icon: Icons.people_outline,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: StatCard(
                          title: 'ROI',
                          value: stats['roi'] ?? '0%',
                          change: 'Return on Investment',
                          isPositive: true,
                          icon: Icons.trending_up,
                        ),
                      ),
                    ],
                  );
              },
            ),

            const SizedBox(height: 32),

            // --- SECTION: DANH SÁCH COUPON (LIST) ---
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header của Bảng
                  CouponListHeader(onCreateCoupon: _showCreateCouponDialog),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),

                  // Danh sách Items
                  _controller.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _controller.coupons.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(40.0),
                          child: Center(
                            child: Text(
                              'Chưa có coupon nào',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _controller.coupons.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xFFE5E7EB),
                          ),
                           itemBuilder: (context, index) {
                             return CouponItem(
                               coupon: _controller.coupons[index],
                               isMobile: isMobile,
                               onEdit: () => _showEditCouponDialog(
                                 _controller.coupons[index],
                               ),
                               onDelete: () => _showDeleteCouponDialog(
                                 _controller.coupons[index],
                               ),
                             );
                           },
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
