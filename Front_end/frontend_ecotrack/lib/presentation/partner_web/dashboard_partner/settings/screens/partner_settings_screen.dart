import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/api_client.dart';
import 'package:frontend_ecotrack/core/services/partner_service.dart';

class PartnerSettingsScreen extends StatefulWidget {
  const PartnerSettingsScreen({super.key});

  @override
  State<PartnerSettingsScreen> createState() => _PartnerSettingsScreenState();
}

class _PartnerSettingsScreenState extends State<PartnerSettingsScreen> {
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();

  late final PartnerApi _repo;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final api = ApiClient(storage: const FlutterSecureStorage());
    _repo = PartnerApi(client: api);
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await _repo.getSettings();
    _companyCtrl.text = data['companyName'] ?? '';
    _emailCtrl.text = data['email'] ?? '';
    _phoneCtrl.text = data['phoneNumber'] ?? '';
    _websiteCtrl.text = data['website'] ?? '';
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    await _repo.updateSettings({
      'companyName': _companyCtrl.text,
      'email': _emailCtrl.text,
      'phoneNumber': _phoneCtrl.text,
      'website': _websiteCtrl.text,
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã lưu thay đổi')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _pageHeader(),
                      const SizedBox(height: 24),
                      _content(),
                      const SizedBox(height: 24),
                      _actions(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ================= UI =================

  Widget _pageHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'Cài đặt đối tác',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 4),
        Text(
          'Quản lý thông tin doanh nghiệp đối tác',
          style: TextStyle(color: Colors.black54),
        ),
      ],
    );
  }

  Widget _content() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _section(
              title: 'Doanh nghiệp',
              children: [
                _field('Tên công ty', _companyCtrl),
                _field('Website', _websiteCtrl),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: _section(
              title: 'Liên hệ',
              children: [
                _field('Email', _emailCtrl),
                _field('Số điện thoại', _phoneCtrl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _field(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: ctrl,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions() {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 160,
        height: 40,
        child: ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5EAC24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          child: const Text(
            'Lưu thay đổi',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  BoxDecoration _card() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 6),
      ),
    ],
  );
}
