import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:frontend_ecotrack/core/services/coupon_service.dart';

class CreateCouponDialog extends StatefulWidget {
  final Function(Map<String, dynamic>)? onCreateCoupon;

  const CreateCouponDialog({super.key, this.onCreateCoupon});

  @override
  State<CreateCouponDialog> createState() => _CreateCouponDialogState();
}

class _CreateCouponDialogState extends State<CreateCouponDialog> {
  final _codeController = TextEditingController();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _limitController = TextEditingController();
  final _requiredPointsController = TextEditingController();
  final _maxRedeemPerUserController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _selectedDiscountType;
  String? _selectedCategory;
  String? _selectedBadgeLabel;
  String? _locationScope = 'NATIONWIDE'; // Mặc định Toàn quốc
  String? _selectedProvince;
  DateTime? _selectedStartDate;
  DateTime? _selectedDate;
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  final ImagePicker _imagePicker = ImagePicker();
  final CouponService _couponService = CouponService();

  List<String> _provinces = [];

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        10,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Format giá trị giảm giá để hiển thị
  String _formatDiscountValueDisplay() {
    final text = _discountValueController.text.trim();
    if (text.isEmpty) return '';

    final value = double.tryParse(text);
    if (value == null) return '';

    if (_selectedDiscountType == 'percent') {
      return '${value.toStringAsFixed(0)}%';
    } else if (_selectedDiscountType == 'fixed') {
      return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
    }
    return '';
  }

  // Format giá gốc để hiển thị
  String _formatOriginalPriceDisplay() {
    final text = _originalPriceController.text.trim();
    if (text.isEmpty) return '';

    final value = double.tryParse(text);
    if (value == null) return '';

    return '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  // Tính giá sau sale (final price)
  double? _calculateFinalPrice() {
    final originalPriceText = _originalPriceController.text.trim();
    final discountValueText = _discountValueController.text.trim();

    if (originalPriceText.isEmpty || discountValueText.isEmpty) {
      return null;
    }

    final originalPrice = double.tryParse(originalPriceText);
    final discountValue = double.tryParse(discountValueText);

    if (originalPrice == null || discountValue == null || originalPrice <= 0) {
      return null;
    }

    if (_selectedDiscountType == 'percent') {
      // Giảm theo phần trăm: finalPrice = originalPrice * (1 - discountValue/100)
      final result = originalPrice * (1 - discountValue / 100.0);
      return result > 0 ? result : 0.0;
    } else if (_selectedDiscountType == 'fixed') {
      // Giảm số tiền cố định: finalPrice = originalPrice - discountValue
      final result = originalPrice - discountValue;
      return result > 0 ? result : 0.0;
    } else if (_selectedDiscountType == 'free') {
      // Miễn phí
      return 0.0;
    }

    return null;
  }

  // Format giá sau sale để hiển thị
  String _formatFinalPriceDisplay() {
    final finalPrice = _calculateFinalPrice();
    if (finalPrice == null) return '';

    return '${finalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }

  void _generateRandomCouponCode() {
    setState(() {
      _codeController.text = _generateRandomCode();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProvinces();
    // Add listener để format hiển thị giá trị
    _discountValueController.addListener(() {
      setState(() {}); // Trigger rebuild để cập nhật hiển thị
    });
    _originalPriceController.addListener(() {
      setState(() {}); // Trigger rebuild để cập nhật hiển thị
    });
  }

  Future<void> _loadProvinces() async {
    try {
      final String response = await rootBundle.loadString(
        'vietnamRegions.json',
      );
      final List<dynamic> data = json.decode(response);
      setState(() {
        _provinces = data.map((e) => e['name'] as String).toList();
      });
    } catch (e) {
      debugPrint('Error loading provinces: $e');
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _discountValueController.dispose();
    _originalPriceController.dispose();
    _limitController.dispose();
    _requiredPointsController.dispose();
    _maxRedeemPerUserController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime selectedDate = _selectedDate ?? DateTime.now();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy', 'vi').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month - 1,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Calendar
                    CalendarDatePicker(
                      initialDate: _selectedDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      currentDate: DateTime.now(),
                      onDateChanged: (date) {
                        selectedDate = date;
                      },
                      initialCalendarMode: DatePickerMode.day,
                    ),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, selectedDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008000),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDialog<DateTime>(
      context: context,
      builder: (context) {
        DateTime selectedDate = _selectedStartDate ?? DateTime.now();
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxWidth: 350),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          DateFormat('MMMM yyyy', 'vi').format(selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month - 1,
                                  );
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right, size: 20),
                              onPressed: () {
                                setDialogState(() {
                                  selectedDate = DateTime(
                                    selectedDate.year,
                                    selectedDate.month + 1,
                                  );
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Calendar
                    CalendarDatePicker(
                      initialDate: _selectedStartDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                      currentDate: DateTime.now(),
                      onDateChanged: (date) {
                        selectedDate = date;
                      },
                      initialCalendarMode: DatePickerMode.day,
                    ),
                    const SizedBox(height: 16),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, selectedDate),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF008000),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    if (picked != null && picked != _selectedStartDate) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tạo Coupon Mới',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Thiết lập coupon giảm giá mới cho người dùng EcoTrack',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.grey[400], size: 24),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Mã Coupon'),
                    TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        hintText: 'vd: ECO25OFF',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                            color: Color(0xFF008000),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: Container(
                          margin: const EdgeInsets.all(4),
                          child: ElevatedButton(
                            onPressed: _generateRandomCouponCode,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF008000),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Tạo random',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upload ảnh
                    _buildLabel('Ảnh Thumbnail'),
                    _buildImageUploadField(),
                    const SizedBox(height: 16),

                    // --- DROPDOWN ĐÃ SỬA ---
                    _buildLabel('Loại Giảm Giá'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedDiscountType,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[400],
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 3,
                          hint: Text(
                            'Chọn loại giảm giá',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w400,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'percent',
                              child: Text('Phần trăm (%)'),
                            ),
                            DropdownMenuItem(
                              value: 'fixed',
                              child: Text('Số tiền cố định (VNĐ)'),
                            ),
                            DropdownMenuItem(
                              value: 'free',
                              child: Text('Miễn phí'),
                            ),
                          ],
                          onChanged: (val) {
                            setState(() => _selectedDiscountType = val);
                            // Trigger rebuild để cập nhật format hiển thị
                          },
                        ),
                      ),
                    ),

                    // -----------------------
                    // Chỉ hiển thị các field này nếu KHÔNG phải "miễn phí"
                    if (_selectedDiscountType != 'free') ...[
                      const SizedBox(height: 16),
                      _buildLabel('Giá Trị Giảm'),
                      _buildTextField(
                        controller: _discountValueController,
                        hint: 'vd: 25 hoặc 50000',
                      ),
                      if (_discountValueController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatDiscountValueDisplay(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildLabel('Giá Gốc (Optional)'),
                      _buildTextField(
                        controller: _originalPriceController,
                        hint: 'vd: 100000',
                      ),
                      if (_originalPriceController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _formatOriginalPriceDisplay(),
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      _buildLabel('Giá Khi Sale'),
                      TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _formatFinalPriceDisplay(),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: _formatFinalPriceDisplay().isEmpty
                              ? Colors.grey[400]
                              : const Color(0xFF16A34A),
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tự động tính từ giá trị giảm và giá gốc',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildLabel('Giới Hạn Sử Dụng'),
                    _buildTextField(
                      controller: _limitController,
                      hint: 'vd: 500',
                    ),

                    // --- NHÓM THÔNG TIN VOUCHER ---
                    const SizedBox(height: 16),
                    _buildLabel('Tiêu Đề Voucher'),
                    _buildTextField(
                      controller: _titleController,
                      hint: 'vd: Giảm 20% cho đơn hàng đầu tiên',
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Mô Tả Ngắn'),
                    _buildTextField(
                      controller: _shortDescriptionController,
                      hint: 'Mô tả ngắn về voucher',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Danh Mục'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[400],
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 3,
                          hint: Text(
                            'Chọn danh mục',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w400,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Ăn uống',
                              child: Text('Ăn uống'),
                            ),
                            DropdownMenuItem(
                              value: 'Mua sắm',
                              child: Text('Mua sắm'),
                            ),
                            DropdownMenuItem(
                              value: 'Di chuyển',
                              child: Text('Di chuyển'),
                            ),
                            DropdownMenuItem(
                              value: 'Dịch vụ',
                              child: Text('Dịch vụ'),
                            ),
                            DropdownMenuItem(
                              value: 'Khác',
                              child: Text('Khác'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedCategory = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Nhãn Badge (Optional)'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedBadgeLabel,
                          isExpanded: true,
                          icon: Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.grey[400],
                          ),
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          elevation: 3,
                          hint: Text(
                            'Chọn nhãn (tuỳ chọn)',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w400,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Hot',
                              child: Text('🔥 Hot'),
                            ),
                            DropdownMenuItem(
                              value: 'Mới',
                              child: Text('🎉 Mới'),
                            ),
                            DropdownMenuItem(
                              value: 'Giới hạn',
                              child: Text('⏰ Giới hạn'),
                            ),
                            DropdownMenuItem(
                              value: 'VIP',
                              child: Text('💎 VIP'),
                            ),
                            DropdownMenuItem(
                              value: 'Độc quyền',
                              child: Text('⭐ Độc quyền'),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedBadgeLabel = val),
                        ),
                      ),
                    ),

                    // Chỉ hiển thị "Số Điểm Yêu Cầu" nếu KHÔNG phải "miễn phí"
                    if (_selectedDiscountType != 'free') ...[
                      const SizedBox(height: 16),
                      _buildLabel('Số Điểm Yêu Cầu'),
                      _buildTextField(
                        controller: _requiredPointsController,
                        hint: 'vd: 300 điểm',
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildLabel(
                      'Giới Hạn Số Lần Sử Dụng Cho 1 Người Dùng (Optional)',
                    ),
                    _buildTextField(
                      controller: _maxRedeemPerUserController,
                      hint: 'vd: 1 (mỗi người chỉ được đổi 1 lần)',
                    ),

                    // --- THỜI GIAN ---
                    const SizedBox(height: 16),
                    _buildLabel('Ngày Bắt Đầu'),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _selectedStartDate == null
                              ? ''
                              : DateFormat(
                                  'dd/MM/yyyy',
                                ).format(_selectedStartDate!),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedStartDate == null
                              ? Colors.grey[400]
                              : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'dd/mm/yyyy',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF008000),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.black87,
                            ),
                            onPressed: () => _selectStartDate(context),
                          ),
                        ),
                        onTap: () => _selectStartDate(context),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Ngày Hết Hạn'),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: TextField(
                        readOnly: true,
                        controller: TextEditingController(
                          text: _selectedDate == null
                              ? ''
                              : DateFormat('dd/MM/yyyy').format(_selectedDate!),
                        ),
                        style: TextStyle(
                          fontSize: 14,
                          color: _selectedDate == null
                              ? Colors.grey[400]
                              : const Color(0xFF111827),
                        ),
                        decoration: InputDecoration(
                          hintText: 'dd/mm/yyyy',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF008000),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: const Icon(
                              Icons.calendar_today_outlined,
                              size: 18,
                              color: Colors.black87,
                            ),
                            onPressed: () => _selectDate(context),
                          ),
                        ),
                        onTap: () => _selectDate(context),
                      ),
                    ),

                    // --- ĐỊA ĐIỂM ---
                    const SizedBox(height: 16),
                    _buildLabel('Phạm Vi Áp Dụng'),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Toàn quốc',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: 'NATIONWIDE',
                            groupValue: _locationScope,
                            onChanged: (value) {
                              setState(() {
                                _locationScope = value;
                                _selectedProvince = null;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text(
                              'Theo tỉnh',
                              style: TextStyle(fontSize: 14),
                            ),
                            value: 'PROVINCE',
                            groupValue: _locationScope,
                            onChanged: (value) {
                              setState(() {
                                _locationScope = value;
                              });
                            },
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                          ),
                        ),
                      ],
                    ),
                    if (_locationScope == 'PROVINCE') ...[
                      const SizedBox(height: 16),
                      _buildLabel('Chọn Tỉnh/Thành Phố'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedProvince,
                            isExpanded: true,
                            icon: Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.grey[400],
                            ),
                            dropdownColor: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            elevation: 3,
                            hint: Text(
                              'Chọn tỉnh/thành phố',
                              style: TextStyle(
                                color: Colors.grey[400],
                                fontSize: 14,
                              ),
                            ),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF111827),
                              fontWeight: FontWeight.w400,
                            ),
                            items: _provinces
                                .map(
                                  (province) => DropdownMenuItem(
                                    value: province,
                                    child: Text(province),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _selectedProvince = val),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF3F4F6)),

            // Footer Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () async {
                        // Validate form
                        if (_codeController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập mã coupon'),
                            ),
                          );
                          return;
                        }
                        if (_selectedDiscountType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn loại giảm giá'),
                            ),
                          );
                          return;
                        }
                        // Chỉ validate giá trị giảm nếu KHÔNG phải "miễn phí"
                        if (_selectedDiscountType != 'free' && _discountValueController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập giá trị giảm'),
                            ),
                          );
                          return;
                        }
                        if (_limitController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng nhập giới hạn sử dụng'),
                            ),
                          );
                          return;
                        }
                        if (_selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng chọn ngày hết hạn'),
                            ),
                          );
                          return;
                        }

                        // Upload ảnh trước nếu có
                        String? imageUrl = _uploadedImageUrl;
                        if (_selectedImageBytes != null && imageUrl == null) {
                          setState(() {
                            _isUploadingImage = true;
                          });
                          try {
                            imageUrl = await _couponService.uploadImageBytes(
                              _selectedImageBytes!,
                              _selectedImage!.name,
                            );
                            setState(() {
                              _uploadedImageUrl = imageUrl;
                              _isUploadingImage = false;
                            });
                          } catch (e) {
                            setState(() {
                              _isUploadingImage = false;
                            });
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi upload ảnh: $e')),
                              );
                            }
                            return;
                          }
                        }

                        // Tạo data để gửi API
                        final locationText = _locationScope == 'PROVINCE'
                            ? _selectedProvince
                            : 'Toàn quốc';

                        final couponData = {
                          'code': _codeController.text.toUpperCase(),
                          if (_titleController.text.isNotEmpty)
                            'title': _titleController.text,
                          if (_shortDescriptionController.text.isNotEmpty)
                            'shortDescription':
                                _shortDescriptionController.text,
                          'description': _descriptionController.text,
                          if (_selectedCategory != null)
                            'category': _selectedCategory,
                          if (_selectedBadgeLabel != null)
                            'badgeLabel': _selectedBadgeLabel,
                          'discountType':
                              _selectedDiscountType, // "percent", "fixed", hoặc "free"
                          'discountValue': _selectedDiscountType == 'free'
                              ? 0.0
                              : (double.tryParse(
                                      _discountValueController.text,
                                    ) ??
                                    0.0),
                          if (_originalPriceController.text.isNotEmpty &&
                              _selectedDiscountType != 'free')
                            'originalPrice': double.tryParse(
                              _originalPriceController.text,
                            ),
                          'usageLimit':
                              int.tryParse(_limitController.text) ?? 0,
                          'requiredPoints': _selectedDiscountType == 'free'
                              ? 0
                              : (int.tryParse(_requiredPointsController.text) ??
                                    0),
                          if (_maxRedeemPerUserController.text.isNotEmpty)
                            'maxRedeemPerUser': int.tryParse(
                              _maxRedeemPerUserController.text,
                            ),
                          if (_selectedStartDate != null)
                            'startDate': _selectedStartDate!
                                .toIso8601String()
                                .split('T')[0], // Format: YYYY-MM-DD
                          'expiryDate': _selectedDate!.toIso8601String().split(
                            'T',
                          )[0], // Format: YYYY-MM-DD
                          if (_locationScope != null)
                            'locationScope': _locationScope,
                          if (locationText != null)
                            'locationText': locationText,
                          if (imageUrl != null) 'thumbnailUrl': imageUrl,
                        };

                        // Gọi callback
                        if (widget.onCreateCoupon != null) {
                          final success = await widget.onCreateCoupon!(
                            couponData,
                          );
                          if (success && context.mounted) {
                            Navigator.pop(context);
                          }
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF008000),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: _isUploadingImage
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Tạo Coupon',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Hủy',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
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
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF008000), width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildImageUploadField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ảnh preview bên trái 150x150
        if (_selectedImageBytes != null || _uploadedImageUrl != null)
          Container(
            margin: const EdgeInsets.only(right: 16),
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: _uploadedImageUrl != null
                  ? Image.network(
                      '${dotenv.env['API_BASE_URL']}$_uploadedImageUrl',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.error, color: Colors.red),
                        );
                      },
                    )
                  : Image.memory(_selectedImageBytes!, fit: BoxFit.cover),
            ),
          ),

        // Nút chọn ảnh và thông tin bên phải
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OutlinedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.image_outlined, size: 18),
                label: const Text('Chọn ảnh'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                  foregroundColor: const Color(0xFF111827),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              if (_selectedImageBytes != null && _uploadedImageUrl == null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Ảnh sẽ được upload khi bạn nhấn "Tạo Coupon"',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image != null) {
        // Đọc bytes từ XFile (hoạt động trên cả web và mobile)
        final bytes = await image.readAsBytes();

        // Kiểm tra kích thước file
        if (bytes.length > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ảnh quá lớn, tối đa 5MB')),
            );
          }
          return;
        }
        setState(() {
          _selectedImage = image;
          _selectedImageBytes = bytes;
          _uploadedImageUrl = null; // Reset URL khi chọn ảnh mới
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi chọn ảnh: $e')));
      }
    }
  }
}
