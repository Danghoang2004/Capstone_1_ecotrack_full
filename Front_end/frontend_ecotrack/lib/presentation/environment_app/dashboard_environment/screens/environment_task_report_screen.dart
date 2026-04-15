import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/environment_task_service.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EnvironmentTaskReportScreen extends StatefulWidget {
  final EnvironmentCleanupTask task;

  const EnvironmentTaskReportScreen({super.key, required this.task});

  @override
  State<EnvironmentTaskReportScreen> createState() =>
      _EnvironmentTaskReportScreenState();
}

class _EnvironmentTaskReportScreenState
    extends State<EnvironmentTaskReportScreen> {
  static const Color _bgColor = Color(0xFFEAF2ED);
  static const Color _surfaceColor = Color(0xFFFFFFFF);
  static const Color _borderColor = Color(0xFFC6D8CD);
  static const Color _titleColor = Color(0xFF183126);
  static const Color _mutedTextColor = Color(0xFF55695D);
  static const Color _primaryColor = Color(0xFF2F7D4B);
  static const Color _submitButtonColor = Color(0xFF5EAC24);
  static const Color _primarySoftColor = Color(0xFFDCEFE3);

  final EnvironmentTaskService _taskService = EnvironmentTaskService();
  final TextEditingController _noteController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  Uint8List? _selectedBytes;
  Position? _position;
  bool _loadingGps = true;
  bool _isSubmitting = false;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    _resolveLocation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.task.canSubmitCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chỉ team lead mới được báo cáo hoàn tất task.'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      });
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _friendlyError(Object error) {
    final text = error.toString().replaceFirst('Exception: ', '');
    if (text.contains('permission') || text.contains('quyền')) {
      return 'Ứng dụng chưa có quyền vị trí hoặc camera.';
    }
    return text;
  }

  Future<void> _resolveLocation() async {
    setState(() {
      _loadingGps = true;
      _inlineError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('GPS đang tắt. Vui lòng bật dịch vụ vị trí.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Không có quyền truy cập vị trí.');
      }

      final current = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _position = current;
        _loadingGps = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingGps = false;
        _inlineError = _friendlyError(e);
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1600,
      );

      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();

      setState(() {
        _selectedImage = image;
        _selectedBytes = bytes;
        _inlineError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _inlineError = _friendlyError(e));
    }
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (!widget.task.canSubmitCompletion) {
      setState(() => _inlineError = 'Chỉ team lead mới được báo cáo task này.');
      return;
    }

    if (_selectedImage == null) {
      setState(
        () => _inlineError = 'Vui lòng chụp ảnh hoặc chọn ảnh trước khi gửi.',
      );
      return;
    }

    if (_position == null) {
      await _resolveLocation();
      if (_position == null) {
        setState(() => _inlineError = 'Chưa lấy được GPS. Vui lòng thử lại.');
        return;
      }
    }

    if (_noteController.text.trim().isEmpty) {
      setState(() => _inlineError = 'Vui lòng nhập ghi chú hoàn tất.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _inlineError = null;
    });

    try {
      final imageUrl = await _taskService.uploadCompletionImage(
        _selectedImage!.path,
      );

      await _taskService.completeTask(
        taskId: widget.task.taskId,
        afterImageUrl: imageUrl,
        completionNote: _noteController.text.trim(),
        gpsLat: _position!.latitude.toStringAsFixed(7),
        gpsLong: _position!.longitude.toStringAsFixed(7),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã gửi báo cáo hoàn tất cho admin duyệt.'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _inlineError = _friendlyError(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final hasImage = _selectedImage != null;
    final hasNote = _noteController.text.trim().isNotEmpty;
    final completedRequiredSteps = (hasImage ? 1 : 0) + (hasNote ? 1 : 0);

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        foregroundColor: _titleColor,
        title: const Text(
          'Báo Cáo Xử Lý',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
        ),
        scrolledUnderElevation: 0,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.reportTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: _titleColor,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildStatusPill(
                      icon: hasImage
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      label: hasImage ? 'Ảnh: Đã chọn' : 'Ảnh: Chưa chọn',
                      done: hasImage,
                    ),
                    _buildStatusPill(
                      icon: hasNote
                          ? Icons.check_circle_outline
                          : Icons.radio_button_unchecked,
                      label: hasNote
                          ? 'Ghi chú: Đã nhập'
                          : 'Ghi chú: Chưa nhập',
                      done: hasNote,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _detailItem(
                  'Giao lúc',
                  DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt),
                ),
                _detailItem(
                  'Bắt đầu',
                  task.plannedStartAt == null
                      ? 'Chưa đặt'
                      : DateFormat(
                          'HH:mm dd/MM/yyyy',
                        ).format(task.plannedStartAt!),
                ),
                _detailItem(
                  'Kết thúc',
                  task.plannedEndAt == null
                      ? 'Chưa đặt'
                      : DateFormat(
                          'HH:mm dd/MM/yyyy',
                        ).format(task.plannedEndAt!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_inlineError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFF5B4B4), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFB91C1C),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _inlineError!,
                      style: const TextStyle(
                        color: Color(0xFFB91C1C),
                        fontWeight: FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          _buildSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle(
                  title: 'Ảnh hiện trường sau xử lý',
                  subtitle: 'Bước 1/2 - cần ảnh rõ để admin duyệt nhanh hơn',
                ),
                const SizedBox(height: 12),
                if (_selectedBytes != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(
                      _selectedBytes!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  )
                else
                  Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F8F6),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _borderColor, width: 1),
                    ),
                    child: const Center(
                      child: Text(
                        'Chưa có ảnh được chọn',
                        style: TextStyle(
                          color: _mutedTextColor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_alt_outlined, size: 18),
                        label: const Text('Chụp ảnh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _primaryColor),
                          backgroundColor: _primarySoftColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.gallery),
                        icon: const Icon(
                          Icons.photo_library_outlined,
                          size: 18,
                        ),
                        label: const Text('Chọn ảnh'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _primaryColor,
                          side: const BorderSide(color: _primaryColor),
                          backgroundColor: _primarySoftColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _borderColor),
            ),
            child: TextField(
              controller: _noteController,
              enabled: !_isSubmitting,
              minLines: 2,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Ghi chú hoàn tất',
                hintText: 'Mô tả nhanh quá trình xử lý tại điểm này',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _mutedTextColor,
                ),
                hintStyle: const TextStyle(
                  color: _mutedTextColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: const Color(0xFFF2F7F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: _primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                const Icon(Icons.rule, size: 16, color: _mutedTextColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tiến độ hoàn tất: $completedRequiredSteps/2 mục bắt buộc',
                    style: const TextStyle(
                      color: _mutedTextColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.send_outlined, size: 18),
              label: Text(
                _isSubmitting ? 'Đang gửi...' : 'Gửi báo cáo hoàn tất',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _submitButtonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _detailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: _mutedTextColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: _titleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surfaceColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
      ),
      child: child,
    );
  }

  Widget _buildSectionTitle({required String title, required String subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: _titleColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: _mutedTextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPill({
    required IconData icon,
    required String label,
    required bool done,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: done ? _primarySoftColor : const Color(0xFFF2F2F2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: done ? _primaryColor : const Color(0xFFD9D9D9),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: done ? _primaryColor : _mutedTextColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: done ? _primaryColor : _mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }
}
