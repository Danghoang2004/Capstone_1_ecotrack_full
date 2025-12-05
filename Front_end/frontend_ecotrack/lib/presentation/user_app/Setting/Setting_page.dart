import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/App_bar.dart';

class SettingsScreen extends StatefulWidget {
  final bool hideAppBar;

  const SettingsScreen({super.key, this.hideAppBar = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // trạng thái mẫu cho switches / dropdown
  bool thongBao = true;
  bool thongBaoEmail = true;
  bool thongbaoPush = true;
  bool amThanh = true;
  bool cheDoToi = false;
  String ngonNgu = 'Tiếng Việt';

  final List<String> languages = ['Tiếng Việt', 'English'];

  // helper: card box decoration
  BoxDecoration cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  Widget sectionTitle(String title, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1B5E20),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black.withOpacity(0.5),
            ),
          ),
        ],
      ],
    );
  }

  Widget settingRow({
    required Widget leading,
    required Widget title,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 4),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 12),
            Expanded(child: title),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget dividerThin() {
    return Container(height: 1, color: Colors.grey.shade200);
  }

  @override
  Widget build(BuildContext context) {
    final edge = 18.0;
    return Scaffold(
      appBar: widget.hideAppBar ? null : CustomAppBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: edge),
          child: ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Quản lý cài đặt ứng dụng của bạn',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 0, 0, 0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Thông báo card
              Container(
                decoration: cardDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    settingRow(
                      leading: const Icon(
                        Icons.notifications_active,
                        color: Color(0xFF2E7D32),
                      ),
                      title: const Text(
                        'Thông báo',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.notifications,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Bật Thông Báo',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nhận thông báo từ ứng dụng',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: thongBao,
                        onChanged: (v) => setState(() => thongBao = v),
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.email,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Thông Báo Email',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nhận cập nhật qua email',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: thongBaoEmail,
                        onChanged: (v) => setState(() => thongBaoEmail = v),
                        activeTrackColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.push_pin,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Thông Báo Push',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Nhận thông báo push trên thiết bị',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: thongbaoPush,
                        onChanged: (v) => setState(() => thongbaoPush = v),
                        activeTrackColor: const Color(0xFF2E7D32),
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.volume_up,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Âm Thanh',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bật âm thanh cho thông báo',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: amThanh,
                        onChanged: (v) => setState(() => amThanh = v),
                        activeTrackColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Hiển thị & ngôn ngữ
              Container(
                decoration: cardDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    settingRow(
                      leading: const Icon(
                        Icons.language,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Hiển Thị & Ngôn Ngữ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.translate,
                        color: Color(0xFF2E7D32),
                      ),
                      title: const Text(
                        'Ngôn Ngữ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: ngonNgu,
                            items: languages
                                .map(
                                  (e) => DropdownMenuItem(
                                    value: e,
                                    child: Text(e),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => ngonNgu = v ?? ngonNgu),
                          ),
                        ),
                      ),
                    ),
                    dividerThin(),
                    settingRow(
                      leading: const Icon(
                        Icons.dark_mode,
                        color: Color(0xFF2E7D32),
                      ),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chế Độ Tối',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Bật giao diện tối',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      trailing: Switch(
                        value: cheDoToi,
                        onChanged: (v) => setState(() => cheDoToi = v),
                        activeTrackColor: const Color(0xFF2E7D32),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Bảo mật
              Container(
                decoration: cardDecoration(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bảo Mật',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // TODO: xử lý đổi mật khẩu
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Đổi Mật Khẩu',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cập nhật mật khẩu của bạn để bảo vệ tài khoản',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Logout button (đỏ)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await AuthService().logout(); // Xoá JWT khỏi local

                    if (!mounted) return;

                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/login',
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.white),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14.0),
                    child: Text(
                      'Đăng xuất',
                      style: TextStyle(fontSize: 16, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
