import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  final List<Map<String, dynamic>> _availableVouchers = [];
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late final ApiClient _apiClient = ApiClient(storage: _storage);
  bool _isLoadingVouchers = false;
  int? _userPoints;

  @override
  void initState() {
    super.initState();
    _loadAvailableVouchers();
    _loadUserPoints();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserPoints() async {
    try {
      final response = await _apiClient.get('/api/user/profile');
      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        setState(() {
          _userPoints = body['points'] as int?;
        });
      }
    } catch (e) {
      debugPrint('Error loading user points: $e');
    }
  }

  Future<void> _loadAvailableVouchers() async {
    setState(() {
      _isLoadingVouchers = true;
    });

    try {
      final response = await _apiClient.get('/api/user/coupons/available');
      debugPrint('===== DEBUG LOAD VOUCHERS =====');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${utf8.decode(response.bodyBytes)}');

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        debugPrint('Parsed Body: $body');
        debugPrint('Body type: ${body.runtimeType}');

        setState(() {
          _availableVouchers.clear();
          if (body is List) {
            debugPrint('Number of vouchers: ${body.length}');
            for (var voucher in body) {
              debugPrint('Processing voucher: $voucher');
              _availableVouchers.add({
                'couponId': voucher['couponId'],
                'code': voucher['code'] ?? '',
                'title': voucher['title'] ?? '',
                'shortDescription': voucher['shortDescription'] ?? '',
                'description': voucher['description'] ?? '',
                'category': voucher['category'] ?? '',
                'badgeLabel': voucher['badgeLabel'],
                'discountType': voucher['discountType'] ?? 'PERCENT',
                'discountValue': voucher['discountValue'] ?? 0.0,
                'originalPrice': voucher['originalPrice'],
                'finalPrice': voucher['finalPrice'],
                'requiredPoints': voucher['requiredPoints'],
                'thumbnailUrl': voucher['thumbnailUrl'],
                'expiryDate': voucher['expiryDate'] ?? '',
                'usageLimit': voucher['usageLimit'] ?? 0,
                'usedCount': voucher['usedCount'] ?? 0,
                'partnerName': voucher['partnerName'],
                'partnerLogoUrl': voucher['partnerLogoUrl'],
                'serviceArea': voucher['serviceArea'],
                'locationText': voucher['locationText'] ?? '',
              });
            }
            debugPrint('Total vouchers added: ${_availableVouchers.length}');
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
      debugPrint('ERROR loading vouchers: $e');
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

  Future<void> _redeemVoucher(Map<String, dynamic> voucher) async {
    final requiredPoints = voucher['requiredPoints'] as int? ?? 0;
    final couponId = voucher['couponId'] as int?;

    if (couponId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thông tin voucher không hợp lệ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_userPoints == null || _userPoints! < requiredPoints) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Bạn không đủ điểm! Cần $requiredPoints điểm, hiện có ${_userPoints ?? 0} điểm',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Gọi API đổi voucher thật
    try {
      final response = await _apiClient.post('/api/user/coupons/redeem', {
        'couponId': couponId,
      });

      final body = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200 && body['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Đổi voucher thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }

        // Reload points và vouchers
        await _loadUserPoints();
        await _loadAvailableVouchers();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(body['message'] ?? 'Đổi voucher thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}₫';
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
            // --- SECTION: ĐIỂM HIỆN TẠI ---
            Card(
              elevation: 2,
              color: const Color(0xFFF0FDF4),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.stars,
                          color: Color(0xFF16A34A),
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Điểm hiện tại',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              '${_userPoints ?? 0} điểm',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        _loadUserPoints();
                        _loadAvailableVouchers();
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text('Làm mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- SECTION: DANH SÁCH VOUCHER ĐỔI THƯỞNG ---
            Text(
              'Danh Sách Voucher Đổi Thưởng (${_availableVouchers.length})',
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
                : Column(
                    children: _availableVouchers
                        .map((voucher) => _buildVoucherCard(voucher))
                        .toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildVoucherCard(Map<String, dynamic> voucher) {
    final thumbnailUrl = voucher['thumbnailUrl'] as String?;
    final title = voucher['title'] as String? ?? 'Voucher';
    final shortDescription = voucher['shortDescription'] as String? ?? '';
    final locationText = voucher['locationText'] as String? ?? '';
    final originalPrice = voucher['originalPrice'] as double?;
    final finalPrice = voucher['finalPrice'] as double?;
    final requiredPoints = voucher['requiredPoints'] as int? ?? 0;
    final badgeLabel = voucher['badgeLabel'] as String?;
    final expiryDate = voucher['expiryDate'] as String? ?? '';
    final canRedeem = _userPoints != null && _userPoints! >= requiredPoints;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      clipBehavior: Clip.hardEdge,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail bên trái 100px
            SizedBox(
              width: 100,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(color: Colors.grey[200]),
                    child: thumbnailUrl != null && thumbnailUrl.isNotEmpty
                        ? Image.network(
                            '${dotenv.env['API_BASE_URL']}$thumbnailUrl',
                            width: 100,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 100,
                                color: Colors.grey[200],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 100,
                                color: Colors.grey[200],
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 100,
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                  ),
                  // Badge label
                  if (badgeLabel != null)
                    Positioned(
                      top: 6,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF6B00),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(4),
                            bottomRight: Radius.circular(4),
                          ),
                        ),
                        child: Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Content bên phải
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Short description (nội dung)
                    if (shortDescription.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          shortDescription,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Location text (Toàn quốc, tỉnh, etc.)
                    if (locationText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 13,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Expiry date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 13,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Đến $expiryDate',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price & Button row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Price & Points
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (finalPrice != null && finalPrice == 0)
                                const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.card_giftcard,
                                      size: 18,
                                      color: Color(0xFF16A34A),
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Miễn phí',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                  ],
                                )
                              else if (finalPrice != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _formatCurrency(finalPrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF16A34A),
                                      ),
                                    ),
                                    if (originalPrice != null &&
                                        originalPrice > finalPrice) ...[
                                      const SizedBox(width: 8),
                                      Text(
                                        _formatCurrency(originalPrice),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[500],
                                          decoration:
                                              TextDecoration.lineThrough,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    size: 15,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$requiredPoints điểm',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Button
                        ElevatedButton(
                          onPressed: canRedeem
                              ? () => _redeemVoucher(voucher)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: canRedeem
                                ? Colors.black
                                : Colors.grey[300],
                            foregroundColor: canRedeem
                                ? Colors.white
                                : Colors.grey[600],
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            canRedeem ? 'Đổi ngay' : 'Không đủ',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
