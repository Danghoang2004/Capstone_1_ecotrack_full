import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/coupon_service.dart';
import '../models/coupon_model.dart';

class CouponController extends ChangeNotifier {
  final CouponService _couponService = CouponService();

  List<CouponModel> _coupons = [];
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _statistics;

  List<CouponModel> get coupons => _coupons;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get statistics => _statistics;

  // Format số tiền đầy đủ với dấu phẩy
  String _formatCurrencyFull(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  // Get statistics với format
  Map<String, dynamic> getStatistics() {
    if (_statistics == null) {
      return {
        'totalRevenue': '0₫',
        'activeCoupons': '0',
        'usageCount': '0',
        'roi': '0%',
      };
    }

    final totalRevenue = _statistics!['totalRevenue'] as int? ?? 0;
    final activeCoupons = _statistics!['activeCoupons'] as int? ?? 0;
    final totalUsage = _statistics!['totalUsage'] as int? ?? 0;
    final roi = _statistics!['roi'] as double? ?? 0.0;

    return {
      'totalRevenue': '${_formatCurrencyFull(totalRevenue)}₫',
      'activeCoupons': activeCoupons.toString(),
      'usageCount': _formatCurrencyFull(totalUsage),
      'roi': '${roi.toStringAsFixed(0)}%',
    };
  }

  Future<void> loadStatistics() async {
    try {
      final data = await _couponService.getStatistics();
      _statistics = data;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _statistics = null;
      notifyListeners();
    }
  }

  Future<void> loadCoupons() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _couponService.getAllCoupons();
      _coupons = data.map((json) => CouponModel.fromJson(json)).toList();
      _error = null;
      // Load statistics sau khi load coupons
      await loadStatistics();
    } catch (e) {
      _error = e.toString();
      _coupons = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createCoupon(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _couponService.createCoupon(data);
      // Reload danh sách sau khi tạo thành công
      await loadCoupons();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateCoupon(int couponId, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _couponService.updateCoupon(couponId, data);
      // Reload danh sách sau khi cập nhật thành công
      await loadCoupons();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteCoupon(int couponId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _couponService.deleteCoupon(couponId);
      // Reload danh sách sau khi xóa thành công
      await loadCoupons();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
