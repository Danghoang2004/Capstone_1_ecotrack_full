import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/user_app/switch_tabs/ThemeService.dart';

import '../introduction/introduction_page.dart';

class SettingsScreen extends StatefulWidget {
  final bool hideAppBar;

  const SettingsScreen({super.key, this.hideAppBar = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Các biến local
  bool thongBao = true;
  String ngonNgu = 'Tiếng Việt';
  final List<String> languages = ['Tiếng Việt', 'English'];

  // Controllers cho dialog
  late TextEditingController _subjectController;
  late TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _subjectController = TextEditingController();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // --- SỬA ĐỔI: Helper Decoration động theo Theme ---
  BoxDecoration cardDecoration(BuildContext context) {
    // Lấy theme hiện tại
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      // Màu nền card lấy từ theme (Light: White, Dark: Grey tối)
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          // Shadow nhạt hơn hoặc ẩn đi nếu là dark mode
          color: isDark ? Colors.transparent : Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }

  // --- SỬA ĐỔI: Style text động ---
  TextStyle get _headerStyle => TextStyle(
    fontWeight: FontWeight.w600,
    // Tự động chuyển trắng/đen
    color: Theme.of(context).textTheme.bodyMedium?.color,
  );

  TextStyle get _subTextStyle => TextStyle(
    fontSize: 12,
    color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.6),
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
    // Divider màu cũng cần chỉnh nhẹ cho dark mode
    return Container(
      height: 1,
      color: Theme.of(context).dividerColor.withOpacity(0.1),
    );
  }

  void _showContactSupportDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Liên Hệ Hỗ Trợ',
          style: _headerStyle.copyWith(fontSize: 18),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiêu Đề', style: _headerStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: subjectController,
                decoration: InputDecoration(
                  hintText: 'Nhập tiêu đề...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Nội Dung', style: _headerStyle.copyWith(fontSize: 14)),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: 'Nhập nội dung tin nhắn...',
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF2E7D32).withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mail, color: Color(0xFF2E7D32)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'hungdd0307@gmail.com',
                        style: _subTextStyle.copyWith(
                          color: const Color(0xFF2E7D32),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              if (subjectController.text.isEmpty ||
                  messageController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Vui lòng điền đầy đủ thông tin'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              // TODO: Gọi API để gửi tin nhắn hỗ trợ
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tin nhắn đã được gửi thành công'),
                  backgroundColor: Color(0xFF2E7D32),
                ),
              );
              subjectController.dispose();
              messageController.dispose();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text(
              'Gửi',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final edge = 16.0;

    // Lấy instance của ThemeService
    final themeService = ThemeService();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
        // Icon status bar đổi màu ngược lại với nền
        statusBarIconBrightness: themeService.isDarkMode
            ? Brightness.light
            : Brightness.dark,
        statusBarBrightness: themeService.isDarkMode
            ? Brightness.dark
            : Brightness.light,
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4FBF8),

      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 50, 16, 0),
              child: Center(
                child: Text(
                  'Cài Đặt',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Nội dung Settings
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: Column(
                children: [
                  // --- PHẦN 1: THÔNG BÁO ---
                  Container(
                    decoration: cardDecoration(context), // Truyền context vào
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
                            children: [
                              Text('Bật Thông Báo', style: _headerStyle),
                              const SizedBox(height: 4),
                              Text(
                                'Nhận thông báo từ ứng dụng',
                                style: _subTextStyle,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- PHẦN 2: HIỂN THỊ & NGÔN NGỮ ---
                  Container(
                    decoration: cardDecoration(context),
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
                            children: [
                              Text(
                                'Hiển Thị & Ngôn Ngữ',
                                style: _headerStyle.copyWith(fontSize: 16),
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
                          title: Text('Ngôn Ngữ', style: _headerStyle),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: ngonNgu,
                                dropdownColor: Theme.of(
                                  context,
                                ).cardColor, // Dropdown ăn theo màu theme
                                style:
                                    _headerStyle, // Text trong dropdown ăn theo màu theme
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

                        // --- PHẦN QUAN TRỌNG: CHẾ ĐỘ TỐI ---
                        settingRow(
                          leading: const Icon(
                            Icons.dark_mode,
                            color: Color(0xFF2E7D32),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Chế Độ Tối', style: _headerStyle),
                              const SizedBox(height: 4),
                              Text('Bật giao diện tối', style: _subTextStyle),
                            ],
                          ),
                          trailing: Switch(
                            // 1. Lấy giá trị từ ThemeService
                            value: themeService.isDarkMode,
                            // 2. Gọi hàm toggleTheme của ThemeService
                            onChanged: (val) {
                              themeService.toggleTheme(val);
                            },
                            activeTrackColor: const Color(0xFF2E7D32),
                          ),
                        ),
                        // -------------------------------------
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- PHẦN 3: THÔNG TIN & HỖ TRỢ ---
                  Container(
                    decoration: cardDecoration(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thông Tin & Hỗ Trợ',
                          style: _headerStyle.copyWith(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        settingRow(
                          leading: const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFF2E7D32),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Về EcoTrack', style: _headerStyle),
                              const SizedBox(height: 4),
                              Text(
                                'Xem giới thiệu, sứ mệnh và đội ngũ phát triển',
                                style: _subTextStyle,
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                          ),
                          onTap: () {
                            // Lệnh điều hướng sang trang Introduction
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IntroductionPage(),
                              ),
                            );
                          },
                        ),
                        dividerThin(),
                        settingRow(
                          leading: const Icon(
                            Icons.mail_outline,
                            color: Color(0xFF2E7D32),
                          ),
                          title: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Liên Hệ Hỗ Trợ', style: _headerStyle),
                              const SizedBox(height: 4),
                              Text(
                                'Gửi câu hỏi và nhận hỗ trợ từ team',
                                style: _subTextStyle,
                              ),
                            ],
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.color?.withOpacity(0.3),
                          ),
                          onTap: () {
                            _showContactSupportDialog();
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // --- PHẦN 4: TÀI KHOẢN ---
                  Container(
                    decoration: cardDecoration(context),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nút Đăng Xuất
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await AuthService().logoutGoogle();
                              if (!mounted) return;
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/login',
                                (route) => false,
                              );
                            },
                            icon: const Icon(
                              Icons.logout,
                              color: Color.fromARGB(255, 243, 243, 243),
                            ),
                            label: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12.0),
                              child: Text(
                                'Đăng xuất',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                196,
                                17,
                                44,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đăng xuất tài khoản ra khỏi ứng dụng Ecotrack',
                          style: _subTextStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
