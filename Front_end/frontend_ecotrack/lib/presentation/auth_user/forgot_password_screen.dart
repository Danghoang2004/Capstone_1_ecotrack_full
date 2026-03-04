import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'forgot_success_screen.dart'; 

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true; 

  bool _loading = false;
  String? _error;

  final AuthService _authService = AuthService();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _authService.forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    setState(() => _loading = false);

    if (result['success'] == true) {
      // BỎ Dialog đi. Điều hướng sang màn hình Success (State 2 trên Figma)
      // Truyền email qua để hiển thị trên màn hình thành công
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForgotSuccessScreen(email: _emailCtrl.text.trim()),
        ),
      );
    } else {
      setState(() {
        _error = result['message'] ?? 'Đã có lỗi xảy ra';
      });
    }
  }
      
  @override
  Widget build(BuildContext context) {
    // Mã màu lấy trực tiếp từ bản Figma của bạn
    const Color figmaBackground = Color(0xFFF2F9F1); // Nền xanh rất nhạt
    const Color figmaLogoBg = Color(0xFFE2F3D8); // Nền bo góc của logo
    const Color primaryGreen = Color(0xFF327936); // Xanh lá đậm của nút

    return Scaffold(
      backgroundColor: figmaBackground, // Màu nền dịu mắt
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // 1. Khối Logo (Vuông bo góc)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: figmaLogoBg,
                  borderRadius: BorderRadius.circular(20), // Bo góc 20
                ),
                // Icon lá thanh mảnh hơn
                child: const Icon(Icons.eco_outlined, size: 48, color: primaryGreen),
              ),
              const SizedBox(height: 24),
              
              // 2. Tiêu đề (Giảm độ đậm từ w900 xuống w600)
              const Text(
                "Quên mật khẩu?", 
                style: TextStyle(
                  fontSize: 26, 
                  fontWeight: FontWeight.w600, // Nhẹ hơn một chút so với mặc định
                  color: Color(0xFF1A1A1A)
                )
              ),
              const SizedBox(height: 8),
              
              const Text(
                "Cùng nhau bảo vệ môi trường và xây\ndựng tương lai xanh",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 32),

              // 3. Card trắng chứa Form
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  // Bóng đổ nhẹ cho Card nổi lên
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03), 
                      blurRadius: 15, 
                      offset: const Offset(0, 5)
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Căn trái cho text
                    children: [
                      // --- ĐÃ BỔ SUNG TEXT BỊ THIẾU ---
                      const Text(
                        "Nhập email đã đăng ký",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF222222)),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Chúng tôi sẽ gửi liên kết đặt lại mật khẩu qua email",
                        style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.4),
                      ),
                      const SizedBox(height: 20),
                      // --------------------------------

                      // 4. Ô nhập Email
                      TextFormField(
                        controller: _emailCtrl,
                        cursorColor: primaryGreen,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Email của bạn",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.email_outlined, color: Colors.grey),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          // Viền lúc bình thường: Xám nhạt
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          // Viền lúc click vào: Xanh lá
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Vui lòng nhập email";
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16), 

                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        cursorColor: primaryGreen,
                        style: const TextStyle(fontSize: 15),
                        decoration: InputDecoration(
                          hintText: "Mật khẩu mới",
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: primaryGreen, width: 1.5),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.red, width: 1.5),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Vui lòng nhập mật khẩu mới";
                          if (v.length < 6) return "Mật khẩu phải từ 6 ký tự";
                          return null;
                        },
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                      ],

                      const SizedBox(height: 24),

                      // 5. Nút Submit
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryGreen,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _loading
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Gửi mã xác nhận", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // 6. Nút Quay lại
                      Center(
                        child: TextButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, size: 18, color: primaryGreen),
                          label: const Text("Quay lại đăng nhập", style: TextStyle(color: primaryGreen, fontSize: 14, fontWeight: FontWeight.w500)),
                        ),
                      )
                    ],
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