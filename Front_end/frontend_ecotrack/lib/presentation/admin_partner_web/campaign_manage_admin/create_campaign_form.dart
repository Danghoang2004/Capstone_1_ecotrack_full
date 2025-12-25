import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';

class CreateCampaignForm extends StatefulWidget {
  final VoidCallback? onSuccess;
  const CreateCampaignForm({super.key, this.onSuccess});

  @override
  State<CreateCampaignForm> createState() => _CreateCampaignFormState();
}

class _CreateCampaignFormState extends State<CreateCampaignForm> {
  final _formKey = GlobalKey<FormState>();
  late CampaignApi api;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  List partners = [];
  int? selectedPartnerId;
  bool loading = true;

  Uint8List? _webImageBytes;
  File? _mobileImageFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    api = CampaignApi(ApiClient(storage: const FlutterSecureStorage()));
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final res = await api.fetchPartners();
    setState(() {
      partners = res;
      loading = false;
    });
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    if (kIsWeb) {
      final bytes = await picked.readAsBytes();
      setState(() => _webImageBytes = bytes);
    } else {
      setState(() => _mobileImageFile = File(picked.path));
    }
  }

  String _twoDigits(int n) => n.toString().padLeft(2, '0');

  String get startDateStr => _startDate == null
      ? ""
      : "${_startDate!.year}-${_twoDigits(_startDate!.month)}-${_twoDigits(_startDate!.day)}";

  String get endDateStr => _endDate == null
      ? ""
      : "${_endDate!.year}-${_twoDigits(_endDate!.month)}-${_twoDigits(_endDate!.day)}";

  String get startTimeStr => _startTime == null
      ? ""
      : "${_twoDigits(_startTime!.hour)}:${_twoDigits(_startTime!.minute)}:00";

  String get endTimeStr => _endTime == null
      ? ""
      : "${_twoDigits(_endTime!.hour)}:${_twoDigits(_endTime!.minute)}:00";

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView(
                children: [
                  // HÀNG 1: Partner & Tên chiến dịch
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _dropdownPartner()),
                      const SizedBox(width: 20),
                      Expanded(child: _input('Tên chiến dịch', _titleCtrl)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HÀNG 2: Mô tả (Để Full Width vì thường nội dung dài)
                  _input('Mô tả chiến dịch', _descCtrl, maxLines: 3),
                  const SizedBox(height: 16),

                  // HÀNG 3: Địa điểm & Số người tối đa
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _input('Địa điểm', _locationCtrl),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        flex: 1,
                        child: _input(
                          'Số người tối đa',
                          _maxCtrl,
                          isNumber: true,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _datePicker(
                          'Ngày bắt đầu',
                          _startDate,
                          (d) => setState(() => _startDate = d),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _timePicker(
                          'Giờ bắt đầu',
                          _startTime,
                          (t) => setState(() => _startTime = t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _datePicker(
                          'Ngày kết thúc',
                          _endDate,
                          (d) => setState(() => _endDate = d),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _timePicker(
                          'Giờ kết thúc',
                          _endTime,
                          (t) => setState(() => _endTime = t),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // HÀNG 6: Điểm thưởng & Hình ảnh
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 1,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _input('Điểm thưởng', _rewardCtrl, isNumber: true),
                            const SizedBox(height: 24),
                            // Nút bấm ở góc dưới cột 1 để cân bằng
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(flex: 2, child: _imagePicker()),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: 200,
                height: 45,
                child: ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EAC24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Tạo chiến dịch',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Các Widget bổ trợ (giữ nguyên logic của bạn nhưng thêm chút style) ---

  Widget _dropdownPartner() => DropdownButtonFormField<int>(
    value: selectedPartnerId,
    items: partners
        .map<DropdownMenuItem<int>>(
          (p) =>
              DropdownMenuItem(value: p['partnerId'], child: Text(p['name'])),
        )
        .toList(),
    onChanged: (v) => setState(() => selectedPartnerId = v),
    validator: (v) => v == null ? 'Chọn Partner' : null,
    decoration: const InputDecoration(
      labelText: 'Partner',
      border: OutlineInputBorder(),
    ),
  );

  Widget _input(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool isNumber = false,
  }) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: isNumber ? TextInputType.number : null,
    validator: (v) => v!.isEmpty ? 'Không được trống' : null,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
      alignLabelWithHint: true,
    ),
  );

  Widget _datePicker(
    String label,
    DateTime? value,
    Function(DateTime) onPick,
  ) => InkWell(
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );
      if (d != null) onPick(d);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      child: Text(value == null ? 'Chọn ngày' : value.toString().split(' ')[0]),
    ),
  );

  Widget _timePicker(
    String label,
    TimeOfDay? value,
    Function(TimeOfDay) onPick,
  ) => InkWell(
    onTap: () async {
      final t = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (t != null) onPick(t);
    },
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.access_time, size: 18),
      ),
      child: Text(value == null ? 'Chọn giờ' : value.format(context)),
    ),
  );

  Widget _imagePicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Hình ảnh chiến dịch', style: TextStyle(color: Colors.grey)),
      const SizedBox(height: 8),
      InkWell(
        onTap: _pickImage,
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400),
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey.shade50,
          ),
          child: _buildImagePreview(),
        ),
      ),
    ],
  );

  Widget _buildImagePreview() {
    if (kIsWeb && _webImageBytes != null)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
      );
    if (!kIsWeb && _mobileImageFile != null)
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(_mobileImageFile!, fit: BoxFit.cover),
      );
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo_outlined, color: Colors.grey),
          Text('Chọn ảnh', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if ((kIsWeb && _webImageBytes == null) ||
        (!kIsWeb && _mobileImageFile == null)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng chọn ảnh')));
      return;
    }

    final fields = {
      'partnerId': selectedPartnerId.toString(),
      'title': _titleCtrl.text,
      'description': _descCtrl.text,
      'locationAddress': _locationCtrl.text,
      'startDate': startDateStr,
      'endDate': endDateStr,
      'startTime': startTimeStr,
      'endTime': endTimeStr,
      'maxParticipants': _maxCtrl.text,
      'rewardPoints': _rewardCtrl.text,
    };

    try {
      if (kIsWeb) {
        await api.createMultipartBytes(
          fields: fields,
          imageBytes: _webImageBytes!,
          fileName: 'campaign.jpg',
        );
      } else {
        await api.createMultipart(fields: fields, imageFile: _mobileImageFile!);
      }
      if (mounted) {
        // 1. Hiển thị thông báo ở giữa màn hình
        _showSuccessOverlay(context);

        // 2. Đợi 1.5 - 2 giây để người dùng kịp nhìn thông báo trước khi đóng panel và load lại data
        await Future.delayed(const Duration(milliseconds: 1800));

        // 3. Gọi callback để đóng SidePanel và refresh danh sách
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  void _showSuccessOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho bấm ra ngoài để tắt
      builder: (BuildContext context) {
        // Tự động đóng dialog sau 2 giây
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        });

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.rectangle,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10.0,
                  offset: Offset(0.0, 10.0),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Để dialog ôm sát nội dung
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF5EAC24),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Thành công!",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Chiến dịch của bạn đã được tạo thành công.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
