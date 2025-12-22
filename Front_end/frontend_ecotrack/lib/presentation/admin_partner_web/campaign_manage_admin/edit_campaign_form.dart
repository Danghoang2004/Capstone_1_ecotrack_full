import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/CampaignApi.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';

class EditCampaignForm extends StatefulWidget {
  final int id;
  const EditCampaignForm({super.key, required this.id});

  @override
  State<EditCampaignForm> createState() => _EditCampaignFormState();
}

class _EditCampaignFormState extends State<EditCampaignForm> {
  final _formKey = GlobalKey<FormState>();

  late CampaignApi api;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _maxParticipantCtrl = TextEditingController();
  final _rewardPointCtrl = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    api = CampaignApi(ApiClient(storage: const FlutterSecureStorage()));
    _load();
  }

  Future<void> _load() async {
    final c = await api.getDetail(widget.id);

    _titleCtrl.text = c.title;
    _descCtrl.text = c.description ?? "";
    _locationCtrl.text = c.location;
    _maxParticipantCtrl.text = c.maxParticipants.toString();
    _rewardPointCtrl.text = c.rewardPoints.toString();
    _startDate = DateTime.parse(c.startDate);
    _endDate = DateTime.parse(c.endDate);

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  SizedBox(height: 5),
                  _input("Tên chiến dịch", _titleCtrl),
                  _input("Mô tả", _descCtrl, maxLines: 4),
                  _input("Địa điểm", _locationCtrl),
                  _datePicker(
                    "Ngày bắt đầu",
                    _startDate,
                    (d) => setState(() => _startDate = d),
                  ),
                  _datePicker(
                    "Ngày kết thúc",
                    _endDate,
                    (d) => setState(() => _endDate = d),
                  ),
                  _input(
                    "Số người tối đa",
                    _maxParticipantCtrl,
                    isNumber: true,
                  ),
                  _input("Điểm thưởng", _rewardPointCtrl, isNumber: true),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24),
                ),
                child: const Text(
                  "Cập nhật",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      "title": _titleCtrl.text,
      "description": _descCtrl.text,
      "locationAddress": _locationCtrl.text,
      "startDate": _startDate!.toIso8601String().split("T")[0],
      "endDate": _endDate!.toIso8601String().split("T")[0],
      "maxParticipants": int.parse(_maxParticipantCtrl.text),
      "rewardPoints": int.parse(_rewardPointCtrl.text),
    };

    await api.update(widget.id, payload);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cập nhật chiến dịch thành công")),
      );
    }
  }

  Widget _input(
    String label,
    TextEditingController ctrl, {
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        validator: (v) => v == null || v.isEmpty ? "Không được để trống" : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, Function(DateTime) onPick) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d != null) onPick(d);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(
            value == null
                ? "Chọn ngày"
                : "${value.day}/${value.month}/${value.year}",
          ),
        ),
      ),
    );
  }
}
