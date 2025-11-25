import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/presentation/common/primary_button.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    final result = await _authService.login(email, password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      final isAdmin = await _authService.isAdmin();

      if (isAdmin) {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else {
        await _authService.logout();
        setState(() => _error = 'Bạn không có quyền truy cập trang quản trị.');
      }
    } else {
      setState(() {
        _error = result['message'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F5ED),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 15,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 72, 126, 60),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.eco, color: Colors.white, size: 40),
                  ),
                ),
                const SizedBox(height: 15),
                const Text(
                  "Admin Portal",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4A4A4A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Đăng nhập vào tài khoản quản trị của bạn",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),

                // Email Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAdminTextField(
                  hint: "admin@example.com",
                  icon: Icons.email_outlined,
                  controller: _emailCtrl,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Vui lòng nhập email" : null,
                ),
                const SizedBox(height: 20),

                // Mật khẩu Field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Mật khẩu",
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                  ),
                ),
                const SizedBox(height: 8),
                _buildAdminTextField(
                  hint: "Mật khẩu của bạn",
                  icon: Icons.lock_outline,
                  obscure: _obscurePassword,
                  controller: _passwordCtrl,
                  validator: (v) =>
                      v == null || v.isEmpty ? "Vui lòng nhập mật khẩu" : null,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey.shade500,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),

                // Quên mật khẩu?
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // Xử lý quên mật khẩu
                    },
                    child: const Text(
                      "Quên mật khẩu?",
                      style: TextStyle(color: Color(0xFF5EAC24), fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                // Nút Đăng nhập
                PrimaryButton(
                  text: _loading ? "Đang xử lý..." : "Đăng nhập",
                  onPressed: _loading ? null : _login,
                ),
                const SizedBox(height: 20),

                // Footer
                const Text(
                  "© 2025 Admin Portal. Bảo mật được đảm bảo.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hàm xây dựng TextField riêng cho AdminLoginScreen
  Widget _buildAdminTextField({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: const TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500),
        prefixIcon: Icon(icon, color: Colors.grey.shade500),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF5F5F5), // Màu nền xám nhạt
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none, // Không có viền
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: Color(0xFF5EAC24),
            width: 1.5,
          ), // Viền xanh khi focus
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
