import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';

/// Widget chuyên nghiệp để xử lý đăng nhập user
/// Chỉ cho phép ROLE_USER đăng nhập, từ chối ROLE_ADMIN và ROLE_PARTNER
class UserLoginWidget extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final String? title;
  final String? subtitle;

  const UserLoginWidget({
    super.key,
    required this.onLoginSuccess,
    this.title,
    this.subtitle,
  });

  @override
  State<UserLoginWidget> createState() => _UserLoginWidgetState();
}

class _UserLoginWidgetState extends State<UserLoginWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  bool _obscurePassword = true;
  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    try {
      final result = await _authService.login(email, password);

      if (!mounted) return;
      setState(() => _loading = false);

      if (result['success'] == true) {
        final roles = await _authService.getRoles();

        // Chỉ cho phép ROLE_USER đăng nhập
        if (roles.contains("ROLE_USER") &&
            !roles.contains("ROLE_ADMIN") &&
            !roles.contains("ROLE_PARTNER")) {
          widget.onLoginSuccess();
        } else {
          // Từ chối Admin/Partner nhưng không lộ thông tin
          await _authService.logout();
          setState(() {
            _error = 'Email hoặc mật khẩu không đúng';
          });
        }
      } else {
        setState(() {
          _error = result['message'] ?? 'Đăng nhập thất bại';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Lỗi kết nối: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    widget.title ?? 'Đăng Nhập',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF008000),
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 40),

                  // Email field
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'Nhập email của bạn',
                      prefixIcon: const Icon(Icons.mail_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF008000),
                          width: 2,
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Vui lòng nhập email' : null,
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      hintText: 'Nhập mật khẩu',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFF008000),
                          width: 2,
                        ),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty
                        ? 'Vui lòng nhập mật khẩu'
                        : null,
                    onFieldSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),

                  // Login button
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF008000),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Đăng Nhập',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
