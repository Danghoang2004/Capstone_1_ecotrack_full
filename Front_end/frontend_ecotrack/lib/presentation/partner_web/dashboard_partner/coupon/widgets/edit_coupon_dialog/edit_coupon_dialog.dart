import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/coupon_model.dart';

class EditCouponDialog extends StatefulWidget {
  final CouponModel coupon;
  final Function(Map<String, dynamic>)? onUpdateCoupon;

  const EditCouponDialog({
    super.key,
    required this.coupon,
    this.onUpdateCoupon,
  });

  @override
  State<EditCouponDialog> createState() => _EditCouponDialogState();
}

class _EditCouponDialogState extends State<EditCouponDialog> {
  late final TextEditingController _codeController;
  late final TextEditingController _discountValueController;
  late final TextEditingController _limitController;
  late final TextEditingController _descriptionController;

  String? _selectedDiscountType;
  DateTime? _selectedDate;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    // Pre-fill data từ coupon
    _codeController = TextEditingController(text: widget.coupon.code);
    _discountValueController = TextEditingController(
      text: widget.coupon.discountValueNumber.toStringAsFixed(0),
    );
    _limitController = TextEditingController(text: widget.coupon.total.toString());
    _descriptionController = TextEditingController(text: widget.coupon.description);

    // Set discount type
    _selectedDiscountType = widget.coupon.discountType == 'PERCENT' ? 'percent' : 'fixed';

    // Set isActive
    _isActive = widget.coupon.isActive;

    // Parse ngày từ "dd/MM/yyyy" sang DateTime
    try {
      _selectedDate = DateFormat('dd/MM/yyyy').parse(widget.coupon.expiryDate);
    } catch (e) {
      _selectedDate = null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _limitController.dispose();
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
                          'Chỉnh Sửa Coupon',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Cập nhật thông tin coupon giảm giá',
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
                      readOnly: true, // Không cho edit mã coupon
                      style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                      decoration: InputDecoration(
                        hintText: 'vd: ECO25OFF',
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
                        fillColor: Colors.grey[100], // Màu xám để thể hiện readonly
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dropdown Loại Giảm Giá
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
                          ],
                          onChanged: (val) =>
                              setState(() => _selectedDiscountType = val),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    _buildLabel('Giá Trị Giảm'),
                    _buildTextField(
                      controller: _discountValueController,
                      hint: 'vd: 25 hoặc 50000',
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Giới Hạn Sử Dụng'),
                    _buildTextField(
                      controller: _limitController,
                      hint: 'vd: 500',
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
                    const SizedBox(height: 16),
                    _buildLabel('Mô Tả'),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Mô tả ngắn về coupon',
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Tình Trạng Hoạt Động'),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isActive ? 'Hoạt động' : 'Dừng hoạt động',
                            style: TextStyle(
                              fontSize: 14,
                              color: _isActive ? const Color(0xFF16A34A) : Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (value) {
                            setState(() {
                              _isActive = value;
                            });
                          },
                          activeColor: const Color(0xFF16A34A),
                        ),
                      ],
                    ),
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
                            const SnackBar(content: Text('Mã coupon không được để trống')),
                          );
                          return;
                        }
                        if (_selectedDiscountType == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn loại giảm giá')),
                          );
                          return;
                        }
                        if (_discountValueController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập giá trị giảm')),
                          );
                          return;
                        }
                        if (_limitController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng nhập giới hạn sử dụng')),
                          );
                          return;
                        }
                        if (_selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Vui lòng chọn ngày hết hạn')),
                          );
                          return;
                        }

                        // Tạo data để gửi API
                        final couponData = {
                          'code': _codeController.text.toUpperCase(),
                          'description': _descriptionController.text,
                          'discountType': _selectedDiscountType, // "percent" hoặc "fixed"
                          'discountValue': double.tryParse(_discountValueController.text) ?? 0.0,
                          'usageLimit': int.tryParse(_limitController.text) ?? 0,
                          'expiryDate': _selectedDate!.toIso8601String().split('T')[0], // Format: YYYY-MM-DD
                          'isActive': _isActive,
                        };

                        // Gọi callback
                        if (widget.onUpdateCoupon != null) {
                          final success = await widget.onUpdateCoupon!(couponData);
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
                      child: const Text(
                        'Cập Nhật Coupon',
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
}

