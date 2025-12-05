import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'widgets/user_login_widget.dart';

class TestVoucherScreen extends StatefulWidget {
  const TestVoucherScreen({super.key});

  @override
  State<TestVoucherScreen> createState() => _TestVoucherScreenState();
}

class _TestVoucherScreenState extends State<TestVoucherScreen> {
  bool _isAuthenticated = false;
  bool _isCheckingAuth = true;
  final AuthService _authService = AuthService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    final token = await _storage.read(key: 'jwt_token');
    if (token != null) {
      // Kiểm tra token có hợp lệ không bằng cách lấy roles
      try {
        final roles = await _authService.getRoles();
        if (roles.contains("ROLE_USER") &&
            !roles.contains("ROLE_ADMIN") &&
            !roles.contains("ROLE_PARTNER")) {
          setState(() {
            _isAuthenticated = true;
            _isCheckingAuth = false;
          });
          return;
        }
      } catch (e) {
        // Token không hợp lệ
      }
    }
    setState(() {
      _isAuthenticated = false;
      _isCheckingAuth = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingAuth) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthenticated) {
      return UserLoginWidget(
        title: 'Test Voucher',
        subtitle: 'Đăng nhập để tiếp tục',
        onLoginSuccess: () {
          setState(() {
            _isAuthenticated = true;
          });
        },
      );
    }

    return const _TestVoucherContent();
  }
}

class _TestVoucherContent extends StatefulWidget {
  const _TestVoucherContent();

  @override
  State<_TestVoucherContent> createState() => __TestVoucherContentState();
}

class __TestVoucherContentState extends State<_TestVoucherContent> {
  final TextEditingController _voucherController = TextEditingController();
  final List<Map<String, dynamic>> _purchaseHistory = [];
  final List<Map<String, dynamic>> _usedVouchers = [];
  final List<Map<String, dynamic>> _availableVouchers = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient = ApiClient(storage: _storage);
  bool _isLoading = false;
  bool _isLoadingVouchers = false;

  // Demo sản phẩm
  final double _productPrice = 100000.0; // 100k
  Map<String, dynamic>? _appliedCoupon;
  double _finalPrice = 100000.0;

  @override
  void initState() {
    super.initState();
    _loadAvailableVouchers();
  }

  @override
  void dispose() {
    _voucherController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableVouchers() async {
    setState(() {
      _isLoadingVouchers = true;
    });

    try {
      final response = await _apiClient.get('/api/user/coupons/available');
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _availableVouchers.clear();
          if (body is List) {
            for (var voucher in body) {
              _availableVouchers.add({
                'code': voucher['code'] ?? '',
                'description': voucher['description'] ?? '',
                'discountType': voucher['discountType'] ?? 'PERCENT',
                'discountValue': voucher['discountValue'] ?? 0.0,
                'expiryDate': voucher['expiryDate'] ?? '',
                'usageLimit': voucher['usageLimit'] ?? 0,
                'usedCount': voucher['usedCount'] ?? 0,
              });
            }
          }
        });
      } else if (response.statusCode == 401) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vui lòng đăng nhập để xem danh sách voucher'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tải danh sách voucher: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingVouchers = false;
        });
      }
    }
  }

  void _selectVoucher(Map<String, dynamic> voucher) {
    setState(() {
      _voucherController.text = voucher['code'];
    });
    _applyVoucher();
  }

  Future<void> _applyVoucher() async {
    final voucherCode = _voucherController.text.trim();
    if (voucherCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập mã voucher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiClient.post('/api/user/coupons/apply', {
        'code': voucherCode.toUpperCase(),
      });

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && body['success'] == true) {
        final discountType = body['discountType'] as String;
        final discountValue = (body['discountValue'] as num).toDouble();

        // Tính giá sau giảm
        double discountAmount = 0;
        if (discountType == 'PERCENT') {
          discountAmount = (_productPrice * discountValue) / 100;
        } else {
          discountAmount = discountValue;
        }
        final newPrice = (_productPrice - discountAmount)
            .clamp(0, double.infinity)
            .toDouble();

        setState(() {
          _appliedCoupon = {
            'code': voucherCode.toUpperCase(),
            'discountType': discountType,
            'discountValue': discountValue,
            'description': body['description'] ?? '',
            'discountAmount': discountAmount,
          };
          _finalPrice = newPrice;

          _usedVouchers.add({
            'code': voucherCode.toUpperCase(),
            'discountType': discountType,
            'discountValue': discountValue,
            'description': body['description'] ?? '',
            'discountAmount': discountAmount,
            'appliedAt': DateTime.now(),
          });

          _voucherController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Áp dụng voucher thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        _loadAvailableVouchers();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Áp dụng voucher thất bại'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _finalPrice = _productPrice;
    });
  }

  void _purchaseProduct() {
    if (_appliedCoupon == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng áp dụng voucher trước khi mua'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _purchaseHistory.add({
        'product': 'TV Samsung 32 inch',
        'originalPrice': _productPrice,
        'coupon': _appliedCoupon!['code'],
        'discountAmount': _appliedCoupon!['discountAmount'],
        'finalPrice': _finalPrice,
        'discountType': _appliedCoupon!['discountType'],
        'discountValue': _appliedCoupon!['discountValue'],
        'purchaseTime': DateTime.now(),
      });
      _appliedCoupon = null;
      _finalPrice = _productPrice;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Mua hàng thành công! Đã thanh toán ${_formatCurrency(_finalPrice)}',
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Voucher'),
        backgroundColor: const Color(0xFF008000),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- SECTION: SẢN PHẨM DEMO ---
            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.tv,
                            size: 48,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TV Samsung 32 inch',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Giá gốc: ${_formatCurrency(_productPrice)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                  decoration: _appliedCoupon != null
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                              ),
                              if (_appliedCoupon != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Giá sau giảm: ${_formatCurrency(_finalPrice)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                Text(
                                  'Tiết kiệm: ${_formatCurrency(_appliedCoupon!['discountAmount'])}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECTION: DANH SÁCH VOUCHER CÓ SẴN ---
            Text(
              'Danh Sách Voucher Có Sẵn (${_availableVouchers.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _isLoadingVouchers
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _availableVouchers.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có voucher nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _availableVouchers.length,
                      itemBuilder: (context, index) {
                        final voucher = _availableVouchers[index];
                        final discountDisplay =
                            voucher['discountType'] == 'PERCENT'
                            ? '${voucher['discountValue']}%'
                            : _formatCurrency(voucher['discountValue']);
                        final remaining =
                            (voucher['usageLimit'] ?? 0) -
                            (voucher['usedCount'] ?? 0);

                        return GestureDetector(
                          onTap: () => _selectVoucher(voucher),
                          child: Container(
                            width: 200,
                            margin: const EdgeInsets.only(right: 12),
                            child: Card(
                              elevation: 3,
                              color: const Color(0xFFF0FDF4),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            voucher['code'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Giảm $discountDisplay',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF16A34A),
                                          ),
                                        ),
                                        if (voucher['description'] != null &&
                                            voucher['description']
                                                .toString()
                                                .isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              top: 4,
                                            ),
                                            child: Text(
                                              voucher['description'],
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey[700],
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Còn lại: $remaining',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF16A34A),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: const Text(
                                            'Chọn',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const SizedBox(height: 24),

            // --- SECTION: ÁP DỤNG VOUCHER ---
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Áp dụng Voucher',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _voucherController,
                            enabled: _appliedCoupon == null && !_isLoading,
                            decoration: InputDecoration(
                              labelText: 'Nhập mã voucher',
                              hintText: 'VD: ECO20OFF',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: Color(0xFF008000),
                                  width: 2,
                                ),
                              ),
                            ),
                            onSubmitted: (_) => _applyVoucher(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: (_appliedCoupon != null || _isLoading)
                              ? null
                              : _applyVoucher,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008000),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text('Áp Dụng'),
                        ),
                      ],
                    ),
                    if (_appliedCoupon != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Voucher: ${_appliedCoupon!['code']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_appliedCoupon!['description'] != null &&
                                      _appliedCoupon!['description']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      _appliedCoupon!['description'],
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  Text(
                                    'Giảm: ${_appliedCoupon!['discountType'] == 'PERCENT' ? '${_appliedCoupon!['discountValue']}%' : _formatCurrency(_appliedCoupon!['discountValue'])}',
                                    style: const TextStyle(
                                      color: Color(0xFF16A34A),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _removeCoupon,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // --- SECTION: NÚT MUA HÀNG ---
            ElevatedButton(
              onPressed: _appliedCoupon != null ? _purchaseProduct : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008000),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _appliedCoupon != null
                    ? 'Mua Hàng - ${_formatCurrency(_finalPrice)}'
                    : 'Vui lòng áp dụng voucher trước',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION: DANH SÁCH VOUCHER ĐÃ SỬ DỤNG ---
            Text(
              'Danh Sách Voucher Đã Sử Dụng (${_usedVouchers.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _usedVouchers.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.confirmation_number_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa sử dụng voucher nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _usedVouchers.length,
                    itemBuilder: (context, index) {
                      final voucher = _usedVouchers[index];
                      final discountDisplay =
                          voucher['discountType'] == 'PERCENT'
                          ? '${voucher['discountValue']}%'
                          : _formatCurrency(voucher['discountValue']);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        color: const Color(0xFFDCFCE7),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      voucher['code'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Giảm: $discountDisplay',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                    if (voucher['description'] != null &&
                                        voucher['description']
                                            .toString()
                                            .isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          voucher['description'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[700],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    if (voucher['appliedAt'] != null)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          'Áp dụng: ${_formatDateTime(voucher['appliedAt'])}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),

            // --- SECTION: LỊCH SỬ MUA HÀNG ---
            Text(
              'Lịch Sử Mua Hàng (${_purchaseHistory.length})',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _purchaseHistory.isEmpty
                ? Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.shopping_cart_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có đơn hàng nào',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _purchaseHistory.length,
                    itemBuilder: (context, index) {
                      final purchase = _purchaseHistory[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    purchase['product'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    _formatCurrency(purchase['finalPrice']),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Text(
                                    'Giá gốc: ${_formatCurrency(purchase['originalPrice'])}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Voucher: ${purchase['coupon']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF16A34A),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tiết kiệm: ${_formatCurrency(purchase['discountAmount'])}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF16A34A),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Thời gian: ${_formatDateTime(purchase['purchaseTime'])}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
