import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đăng nhập thành công!")));
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        setState(
          () => _error = 'Sai thông tin đăng nhập hoặc mật khẩu không đúng',
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
                const SizedBox(height: 40),
                Image.asset("assets/icons/leaf.png", height: 70),
                const SizedBox(height: 10),
                const Text(
                  "Chào mừng đến với EcoTrack",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Text(
                  "Cùng nhau bảo vệ môi trường và xây dựng tương lai xanh",
                ),
                const SizedBox(height: 25),

                AuthTabSwitcher(
                  isLogin: true,
                  onLoginTap: () {},
                  onRegisterTap: () =>
                      Navigator.pushReplacementNamed(context, "/register"),
                ),
                const SizedBox(height: 30),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Đăng nhập"),
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
                const Divider(),
                const SizedBox(height: 10),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.g_mobiledata, size: 35),
                    SizedBox(width: 20),
                    Icon(Icons.facebook, size: 28),
                  ],
                ),
                const SizedBox(height: 50),
                const Text("2025 EcoTrack. Cùng nhau bảo vệ hành tinh xanh."),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
