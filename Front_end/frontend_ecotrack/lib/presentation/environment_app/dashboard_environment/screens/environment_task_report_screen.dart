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
      setState(() => _inlineError = 'Chưa lấy được GPS. Vui lòng thử lại.');
      return;
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

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Báo cáo task #${task.taskId}'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.reportTitle,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
                const SizedBox(height: 12),
                _detailItem('Loại rác', task.reportCategory),
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
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFCACA0), width: 0.5),
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
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh hiện trường sau xử lý',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2D1D),
                  ),
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
                      color: const Color(0xFFF2F4F7),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE5E7EB),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Chưa có ảnh được chọn',
                        style: TextStyle(
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Vị trí GPS tự động',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
                const SizedBox(height: 10),
                if (_loadingGps)
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Đang lấy vị trí hiện tại...'),
                    ],
                  )
                else if (_position != null)
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        color: Color(0xFF5EAC24),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lat: ${_position!.latitude.toStringAsFixed(5)} | Long: ${_position!.longitude.toStringAsFixed(5)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                            color: Color(0xFF1F2D1D),
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Không lấy được vị trí hiện tại.',
                    style: TextStyle(color: Color(0xFF999999)),
                  ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: _isSubmitting ? null : _resolveLocation,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('Lấy lại GPS'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: TextField(
              controller: _noteController,
              enabled: !_isSubmitting,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Ghi chú hoàn tất',
                hintText: 'Mô tả nhanh quá trình xử lý tại điểm này',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2D1D),
                ),
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE8EFE5)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF5EAC24),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 18),
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
                backgroundColor: const Color(0xFF5EAC24),
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
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF1F2D1D),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
