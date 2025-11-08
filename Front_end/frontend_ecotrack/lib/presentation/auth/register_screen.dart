import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../common/primary_button.dart';
import 'widgets/auth_tab_switcher.dart';

class RegisterScreen extends StatefulWidget {
  final String apiBaseUrl = 'http://192.168.1.89:8080';

  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _usernameFieldKey = GlobalKey<FormFieldState<String>>();
  final _emailFieldKey = GlobalKey<FormFieldState<String>>();
  final _passwordFieldKey = GlobalKey<FormFieldState<String>>();
  final _confirmFieldKey = GlobalKey<FormFieldState<String>>();

  final _storage = const FlutterSecureStorage();

  bool _loading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirm = false;

  // ========= API REGISTER ==========
  Future<void> _register() async {
    setState(() {
      _errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final username = _usernameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final url = Uri.parse('${widget.apiBaseUrl}/api/auth/register');

      final resp = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "username": username,
          "email": email,
          "password": password,
        }),
      );

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body);
        final token = data['token']; // 👈 Lấy token từ phản hồi

        if (token != null) {
          // ✅ Lưu token an toàn
          await _storage.write(key: 'jwt_token', value: token);

          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Đăng ký thành công!")));

          Navigator.pushReplacementNamed(context, "/home");
        } else {
          setState(() => _errorMessage = "Server không trả về token.");
        }
      } else {
        final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};
        setState(() {
          _errorMessage = data['message'] ?? "Đăng ký thất bại.";
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Lỗi mạng: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String? _validateEmail(String? v) {
    if (v == null || v.isEmpty) return "Vui lòng nhập email";
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(v)) return "Email không hợp lệ";
    return null;
  }

  // ======= Widget Custom TextField =======
  Widget _buildInputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required GlobalKey<FormFieldState<String>> fieldKey,
    bool obscure = false,
    String? Function(String?)? validator,
    VoidCallback? toggleVisible,
    bool showVisibilityIcon = false,
  }) {
    return StatefulBuilder(
      builder: (context, setInner) {
        bool focused = false;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Focus(
            onFocusChange: (f) {
              setInner(() => focused = f);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xfff7f7f7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: fieldKey.currentState?.hasError == true
                          ? Colors.red
                          : (focused ? Colors.blue : Colors.transparent),
                      width: 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0xffe0e0e0),
                        offset: Offset(0, 1.5),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: TextFormField(
                    key: fieldKey,
                    controller: controller,
                    obscureText: obscure,
                    validator: validator,
                    decoration: InputDecoration(
                      prefixIcon: Icon(icon, color: Colors.black87),
                      suffixIcon: showVisibilityIcon
                          ? IconButton(
                              icon: Icon(
                                obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: Colors.black54,
                              ),
                              onPressed: toggleVisible,
                            )
                          : null,
                      hintText: hint,
                      hintStyle: const TextStyle(color: Colors.black54),
                      border: InputBorder.none,
                      errorText: null,
                      errorStyle: const TextStyle(height: 0, fontSize: 0),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 18,
                        horizontal: 0,
                      ),
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final err = fieldKey.currentState?.errorText;
                    if (err != null && err.isNotEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(left: 8, top: 4),
                        child: Text(
                          err,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            height: 1.1,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ====== UI ======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
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
                  isLogin: false,
                  onLoginTap: () =>
                      Navigator.pushReplacementNamed(context, "/login"),
                  onRegisterTap: () {},
                ),

                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Tạo tài khoản", style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 10),

                _buildInputField(
                  icon: Icons.person_outline,
                  hint: "Họ và tên",
                  controller: _usernameCtrl,
                  fieldKey: _usernameFieldKey,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? "Vui lòng nhập họ tên"
                      : null,
                ),
                _buildInputField(
                  icon: Icons.email_outlined,
                  hint: "Email của bạn",
                  controller: _emailCtrl,
                  fieldKey: _emailFieldKey,
                  validator: _validateEmail,
                ),
                _buildInputField(
                  icon: Icons.lock_outline,
                  hint: "Mật khẩu",
                  controller: _passwordCtrl,
                  fieldKey: _passwordFieldKey,
                  obscure: !_showPassword,
                  validator: (v) => v == null || v.length < 6
                      ? "Mật khẩu tối thiểu 6 ký tự"
                      : null,
                  showVisibilityIcon: true,
                  toggleVisible: () =>
                      setState(() => _showPassword = !_showPassword),
                ),
                _buildInputField(
                  icon: Icons.lock_outline,
                  hint: "Xác nhận mật khẩu",
                  controller: _confirmCtrl,
                  fieldKey: _confirmFieldKey,
                  obscure: !_showConfirm,
                  validator: (v) {
                    if (v == null || v.isEmpty)
                      return "Vui lòng xác nhận mật khẩu";
                    if (v != _passwordCtrl.text)
                      return "Mật khẩu không trùng khớp";
                    return null;
                  },
                  showVisibilityIcon: true,
                  toggleVisible: () =>
                      setState(() => _showConfirm = !_showConfirm),
                ),

                const SizedBox(height: 20),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),
                PrimaryButton(
                  text: _loading ? "Đang tạo..." : "Tạo tài khoản",
                  onPressed: _loading ? null : _register,
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.g_mobiledata, size: 40),
                    SizedBox(width: 20),
                    Icon(Icons.facebook, size: 30),
                  ],
                ),

                const SizedBox(height: 40),
                const Text("2025 EcoTrack. Cùng nhau bảo vệ hành tinh xanh."),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
