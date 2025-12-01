class CouponModel {
  final int? couponId;
  final String code;
  final String description;
  final String discountType; // "PERCENT" hoặc "FIXED"
  final double _discountValue; // Private field
  final int usedCount;
  final int usageLimit;
  final String expiryDate;
  final bool isActive;

  CouponModel({
    this.couponId,
    required this.code,
    required this.description,
    required this.discountType,
    required double discountValue,
    required this.usedCount,
    required this.usageLimit,
    required this.expiryDate,
    required this.isActive,
  }) : _discountValue = discountValue;

  // Factory constructor từ API response
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    // Format ngày từ "2024-03-15" sang "15/03/2024"
    String formatDate(String dateStr) {
      if (dateStr.isEmpty) return '';
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateStr;
    }

    return CouponModel(
      couponId: json['couponId'] != null ? json['couponId'] as int : null,
      code: json['code'] ?? '',
      description: json['description'] ?? '',
      discountType: json['discountType'] ?? 'PERCENT',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      usedCount: json['usedCount'] ?? 0,
      usageLimit: json['usageLimit'] ?? 0,
      expiryDate: formatDate(json['expiryDate'] ?? ''),
      isActive: json['isActive'] ?? false,
    );
  }

  // Getter để tương thích với UI hiện tại (trả về String)
  String get discountValue => discountType == 'PERCENT'
      ? '${_discountValue.toStringAsFixed(0)}%'
      : '${_discountValue.toStringAsFixed(0)}₫';

  // Getter để lấy giá trị số thực của discountValue
  double get discountValueNumber => _discountValue;

  int get used => usedCount;
  int get total => usageLimit;
}
