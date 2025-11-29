class CouponModel {
  final int? couponId;
  final String code;
  final String? title;
  final String? shortDescription;
  final String description;
  final String? category;
  final String? badgeLabel;
  final String discountType; // "PERCENT" hoặc "FIXED"
  final double _discountValue; // Private field
  final double? originalPrice;
  final double? finalPrice;
  final int usedCount;
  final int usageLimit;
  final int? requiredPoints;
  final String? startDate;
  final String expiryDate;
  final String? locationScope;
  final String? locationText;
  final bool isActive;

  CouponModel({
    this.couponId,
    required this.code,
    this.title,
    this.shortDescription,
    required this.description,
    this.category,
    this.badgeLabel,
    required this.discountType,
    required double discountValue,
    this.originalPrice,
    this.finalPrice,
    required this.usedCount,
    required this.usageLimit,
    this.requiredPoints,
    this.startDate,
    required this.expiryDate,
    this.locationScope,
    this.locationText,
    required this.isActive,
  }) : _discountValue = discountValue;

  // Factory constructor từ API response
  factory CouponModel.fromJson(Map<String, dynamic> json) {
    // Format ngày từ "2024-03-15" sang "15/03/2024"
    String formatDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return '';
      final parts = dateStr.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
      return dateStr;
    }

    return CouponModel(
      couponId: json['couponId'] != null ? json['couponId'] as int : null,
      code: json['code'] ?? '',
      title: json['title'],
      shortDescription: json['shortDescription'],
      description: json['description'] ?? '',
      category: json['category'],
      badgeLabel: json['badgeLabel'],
      discountType: json['discountType'] ?? 'PERCENT',
      discountValue: (json['discountValue'] as num?)?.toDouble() ?? 0.0,
      originalPrice: (json['originalPrice'] as num?)?.toDouble(),
      finalPrice: (json['finalPrice'] as num?)?.toDouble(),
      usedCount: json['usedCount'] ?? 0,
      usageLimit: json['usageLimit'] ?? 0,
      requiredPoints: json['requiredPoints'] as int?,
      startDate: formatDate(json['startDate']),
      expiryDate: formatDate(json['expiryDate'] ?? ''),
      locationScope: json['locationScope'],
      locationText: json['locationText'],
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
