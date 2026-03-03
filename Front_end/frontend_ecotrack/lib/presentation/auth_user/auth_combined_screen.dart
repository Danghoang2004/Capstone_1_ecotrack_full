import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';

// Design system colors
const Color _kPrimaryGreen = Color(0xFF2F6F3E);
const Color _kLightGreen = Color(0xFF4CAF50);
const Color _kBackground = Color(0xFFDDE5DB);
const Color _kCardBg = Color(0xFFF4F7F3);
const Color _kInputBg = Color(0xFFE9EEE7);
const Color _kTextDark = Color(0xFF2C3E2F);
const Color _kTextGray = Color(0xFF7A8B7F);
const Color _kTextLight = Color(0xFFA0A8A2);
const Color _kDividerColor = Color(0xFFC8D2C6);
const Color _kInputIconColor = Color(0xFF8C9A90);

class AuthCombinedScreen extends StatefulWidget {
  final bool initialIsLogin;

  const AuthCombinedScreen({
    super.key,
    this.initialIsLogin = true,
  });

  @override
  State<AuthCombinedScreen> createState() => _AuthCombinedScreenState();
}

class _AuthCombinedScreenState extends State<AuthCombinedScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBackground,
      body: Container(
        color: _kBackground,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: DefaultTabController(
                length: 2,
                initialIndex: widget.initialIsLogin ? 0 : 1,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _kCardBg,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.eco_rounded,
                              color: _kPrimaryGreen, size: 26),
                          SizedBox(width: 8),
                          Text(
                            "EcoTrack",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              color: _kPrimaryGreen,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Chào mừng đến với EcoTrack',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 22,
                          color: _kTextDark,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Cùng nhau bảo vệ môi trường và xây dựng lối sống xanh',
                        style: TextStyle(
                          fontSize: 13,
                          color: _kTextGray,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      TabBar(
                        labelColor: _kPrimaryGreen,
                        unselectedLabelColor: _kTextLight,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        indicator: const UnderlineTabIndicator(
                          borderSide: BorderSide(
                            color: _kPrimaryGreen,
                            width: 3,
                          ),
                        ),
                        tabs: const [
                          Tab(text: 'Đăng nhập'),
                          Tab(text: 'Đăng ký'),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 440,
                        child: const TabBarView(
                          children: [
                            _LoginForm(),
                            _RegisterForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm();

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscurePassword = true;
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

    final result = await _authService.login(email, password);

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['success'] == true) {
      final roles = await _authService.getRoles();

      if (roles.contains("ROLE_ADMIN") || roles.contains("ROLE_PARTNER")) {
        await _authService.logout();
        setState(() {
          _error = 'Email hoặc mật khẩu không đúng';
        });
        return;
      }

      _showSuccessDialog();
    } else {
      setState(() {
        _error = result['message'];
      });
    }
  }

  void _showSuccessDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: "",
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, anim, __, child) {
        return Transform.scale(
          scale: 0.9 + anim.value * 0.1,
          child: Opacity(
            opacity: anim.value,
            child: Center(
              child: Container(
                width: 220,
                padding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 12,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Thông Báo",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.none,
                      ),
                    ),
                    SizedBox(
                      height: 100,
                      child: Lottie.asset(
                        "assets/lotties/animations/success.json",
                        repeat: false,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Đăng nhập tài khoản thành công",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color.fromARGB(255, 34, 34, 34),
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ).then((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/user_app');
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (Navigator.canPop(context)) Navigator.pop(context);
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(
                hint: "Nhập địa chỉ email",
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Vui lòng nhập email";
                if (!v.contains('@')) return "Email không hợp lệ";
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              decoration: _buildInputDecoration(
                hint: "Mật khẩu",
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                    color: _kInputIconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
              validator: (v) =>
                  v == null || v.isEmpty ? "Vui lòng nhập mật khẩu" : null,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                "Quên mật khẩu?",
                style: const TextStyle(
                  fontSize: 13,
                  color: _kTextGray,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            GestureDetector(
              onTap: _loading ? null : _login,
              child: Opacity(
                opacity: _loading ? 0.7 : 1,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kLightGreen, _kPrimaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimaryGreen.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Đăng nhập",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Divider(thickness: 1, color: _kDividerColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'HOẶC',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextGray,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(thickness: 1, color: _kDividerColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              iconColor: Colors.red,
              text: "Đăng nhập với Google",
              onPressed: () {
                // TODO: Google login
              },
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.facebook_rounded,
              iconColor: Colors.blue,
              text: "Đăng nhập với Facebook",
              onPressed: () {
                // TODO: Facebook login
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Chưa có tài khoản? ",
                  style: const TextStyle(
                    color: _kTextGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: "Đăng ký",
                      style: const TextStyle(
                        color: _kPrimaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          final controller =
                              DefaultTabController.of(context);
                          controller.animateTo(1);
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "2025 EcoTrack. Cùng nhau bảo vệ môi trường và xây dựng lối sống xanh.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _kTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterForm extends StatefulWidget {
  const _RegisterForm();

  @override
  State<_RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<_RegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  final _storage = const FlutterSecureStorage();

  bool _loading = false;
  String? _errorMessage;
  bool _showPassword = false;
  bool _showConfirm = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final baseUrl = dotenv.env['API_BASE_URL']!;
      final url = Uri.parse("$baseUrl/api/auth/register");

      final resp = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": email,
          "password": password,
          "username": _usernameCtrl.text.trim(),
        }),
      );

      final data = resp.body.isNotEmpty ? jsonDecode(resp.body) : {};

      if (resp.statusCode == 200) {
        await _storage.write(key: "pending_email", value: email);
        if (!mounted) return;
        Navigator.pushNamed(context, "/otp", arguments: email);
      } else {
        final msg =
            data["message"] ?? data["error"] ?? "Đăng ký thất bại, vui lòng thử lại.";

        setState(() => _errorMessage = msg);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 4),
            TextFormField(
              controller: _usernameCtrl,
              decoration: _buildInputDecoration(
                hint: "Họ và tên",
                icon: Icons.person_outline,
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? "Vui lòng nhập họ tên" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _buildInputDecoration(
                hint: "Địa chỉ email",
                icon: Icons.email_outlined,
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Vui lòng nhập email";
                final regex =
                    RegExp(r'^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$');
                if (!regex.hasMatch(v)) return "Email không hợp lệ";
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: !_showPassword,
              decoration: _buildInputDecoration(
                hint: "Mật khẩu",
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _kInputIconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Vui lòng nhập mật khẩu";
                if (v.length < 6) {
                  return "Mật khẩu phải có ít nhất 6 ký tự";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              decoration: _buildInputDecoration(
                hint: "Xác nhận mật khẩu",
                icon: Icons.lock_outline,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showConfirm
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: _kInputIconColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _showConfirm = !_showConfirm;
                    });
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return "Vui lòng xác nhận mật khẩu";
                }
                if (v != _passwordCtrl.text) {
                  return "Mật khẩu không khớp";
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Checkbox(
                  value: true,
                  onChanged: (_) {},
                ),
                const Expanded(
                  child: Text(
                    'Tôi đồng ý với Điều khoản & Chính sách',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            GestureDetector(
              onTap: _loading ? null : _register,
              child: Opacity(
                opacity: _loading ? 0.7 : 1,
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kLightGreen, _kPrimaryGreen],
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimaryGreen.withOpacity(0.25),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Tạo tài khoản",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Divider(thickness: 1, color: _kDividerColor),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text(
                    'HOẶC',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _kTextGray,
                    ),
                  ),
                ),
                const Expanded(
                  child: Divider(thickness: 1, color: _kDividerColor),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SocialButton(
              icon: Icons.g_mobiledata_rounded,
              iconColor: Colors.red,
              text: "Đăng ký với Google",
              onPressed: () {
                // TODO: Google signup
              },
            ),
            const SizedBox(height: 12),
            _SocialButton(
              icon: Icons.facebook_rounded,
              iconColor: Colors.blue,
              text: "Đăng ký với Facebook",
              onPressed: () {
                // TODO: Facebook signup
              },
            ),
            const SizedBox(height: 20),
            Center(
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Đã có tài khoản? ",
                  style: const TextStyle(
                    color: _kTextGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                  children: [
                    TextSpan(
                      text: "Đăng nhập",
                      style: const TextStyle(
                        color: _kPrimaryGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          final controller =
                              DefaultTabController.of(context);
                          controller.animateTo(0);
                        },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              "2025 EcoTrack. Cùng nhau bảo vệ môi trường và xây dựng lối sống xanh.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: _kTextLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

InputDecoration _buildInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    filled: true,
    fillColor: _kInputBg,
    hintText: hint,
    hintStyle: const TextStyle(
      fontSize: 14,
      color: _kTextLight,
    ),
    prefixIcon: Icon(icon, color: _kInputIconColor),
    suffixIcon: suffixIcon,
    contentPadding: const EdgeInsets.symmetric(vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide.none,
    ),
  );
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  final VoidCallback onPressed;

  const _SocialButton({
    required this.icon,
    required this.iconColor,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFD7E0D5)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              // Custom Google-style circle logo for nicer look
              if (icon == Icons.g_mobiledata_rounded)
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFD7E0D5)),
                  ),
                  child: const Center(
                    child: Text(
                      'G',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ),
                )
              else
                Icon(icon, color: iconColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 14,
                    color: _kTextDark,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

