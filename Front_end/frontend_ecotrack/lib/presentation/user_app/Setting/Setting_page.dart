import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/Home/controllers/profile_controller.dart';

import 'package:frontend_ecotrack/presentation/user_app/Home/widgets/header/header.dart';

class SettingsScreen extends StatefulWidget {
  final bool hideAppBar;

  const SettingsScreen({super.key, this.hideAppBar = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 1. KHỞI TẠO CONTROLLER (Sửa lỗi Undefined name 'controller')
  final ProfileController _profileController = ProfileController();

  // Trạng thái mẫu cho switches / dropdown
  bool thongBao = true;
  bool thongbaoPush = true;
  bool amThanh = true;
  bool cheDoToi = false;
  String ngonNgu = 'Tiếng Việt';

  final List<String> languages = ['Tiếng Việt', 'English'];

  // Helper: card box decoration
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
      backgroundColor: const Color(0xFFF5F7FA), // Màu nền nhẹ cho toàn màn hình
      // BỎ APPBAR, DÙNG BODY VỚI COLUMN
      body: SafeArea(
        child: Column(
          children: [
            // 2. HEADER WIDGET (Nằm trên cùng của Column)
            if (!widget.hideAppBar)
              HeaderWidget(controller: _profileController),

            // 3. PHẦN NỘI DUNG CÀI ĐẶT (Cuộn được)
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: edge),
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    const SizedBox(height: 16),

                    // --- PHẦN 1: THÔNG BÁO ---
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
                              activeColor: Colors.white,
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
                              onChanged: (v) =>
                                  setState(() => thongbaoPush = v),
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

                    // --- PHẦN 2: HIỂN THỊ & NGÔN NGỮ ---
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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

                    // --- PHẦN 3: TÀI KHOẢN & BẢO MẬT (Chứa Đăng Xuất) ---
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
                            'Tài Khoản & Bảo Mật',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Nút Đăng Xuất
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                await AuthService().logout(); // Xoá JWT
                                if (!mounted) return;

                                // Chuyển về trang login
                                Navigator.pushNamedAndRemoveUntil(
                                  context,
                                  '/login',
                                  (route) => false,
                                );
                              },
                              icon: const Icon(
                                Icons.logout,
                                color: Color.fromARGB(255, 243, 243, 243),
                              ), // Icon màu đỏ
                              label: const Padding(
                                padding: EdgeInsets.symmetric(vertical: 14.0),
                                child: Text(
                                  'Đăng xuất',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Color.fromARGB(255, 255, 255, 255),
                                    fontWeight: FontWeight.bold,
                                  ), // Chữ màu đỏ
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(
                                  255,
                                  196,
                                  17,
                                  44,
                                ), // Nền đỏ rất nhạt
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 190, 18, 36),
                                  ), // Viền đỏ nhạt
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Đăng xuất tài khoản ra khỏi ứng dụng Ecotrack',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
