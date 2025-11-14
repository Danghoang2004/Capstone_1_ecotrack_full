import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import '../common/custom_text_field.dart';
import '../common/primary_button.dart';
import 'widgets/auth_tab_switcher.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  final AuthService _authService = AuthService();

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final success = await _authService.login(email, password);

      if (success) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) {
            // Tự đóng sau 3 giây
            Future.delayed(const Duration(seconds: 3), () {
              Navigator.of(context).pop(); // Đóng dialog
              Navigator.pushReplacementNamed(
                context,
                '/user_app',
              ); // Chuyển trang
            });

            return LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Material(
                      color: Colors.transparent,
                      child: AlertDialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        insetPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 24,
                        ),
                        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
                        contentPadding: const EdgeInsets.fromLTRB(
                          20,
                          5,
                          20,
                          20,
                        ),

                        title: const Text(
                          "Đăng nhập thành công",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        content: const Text(
                          "Đang chuyển hướng...",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, height: 1.3),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      } else {
        setState(
          () => _error = 'Sai thông tin đăng nhập hoặc mật khẩu không đúng ',
        );
      }
    } catch (e) {
      setState(() => _error = 'Lỗi kết nối: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Color(0xFF5EAC24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Chào mừng đến với EcoTrack",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Cùng nhau bảo vệ môi trường và xây dựng tương lai xanh",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),

                AuthTabSwitcher(
                  isLogin: true,
                  onLoginTap: () {},
                  onRegisterTap: () =>
                      Navigator.pushReplacementNamed(context, "/register"),
                ),
                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Đăng nhập",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),

                CustomTextField(
                  hint: "Email của bạn",
                  icon: Icons.mail_outline,
                  controller: _emailCtrl,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Vui lòng nhập email" : null,
                ),
                const SizedBox(height: 14),

                CustomTextField(
                  hint: "Mật khẩu",
                  icon: Icons.lock_outline,
                  obscure: true,
                  controller: _passwordCtrl,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Vui lòng nhập mật khẩu" : null,
                ),
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    "Quên mật khẩu?",
                    style: TextStyle(color: Colors.green[700]),
                  ),
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),

                PrimaryButton(
                  text: _loading ? "Đang đăng nhập..." : "Đăng nhập",
                  onPressed: _loading ? null : _login,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1, // độ dày nét
                        color: Colors.grey, // màu vạch
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        'hoặc tiếp tục với',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider(thickness: 1, color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // --- Nút Google ---
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: Image.asset(
                        'assets/icons/google.png',
                        height: 16,
                        width: 16,
                      ),
                      label: const Text(
                        'Google',
                        style: TextStyle(color: Colors.black87),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),

                    const SizedBox(width: 20),

                    // --- Nút Facebook ---
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.facebook,
                        color: Color(0xFF1877F2),
                      ),
                      label: const Text(
                        'Facebook',
                        style: TextStyle(color: Color(0xFF1877F2)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1877F2)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                  "2025 EcoTrack. Cùng nhau bảo vệ hành tinh xanh.",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
