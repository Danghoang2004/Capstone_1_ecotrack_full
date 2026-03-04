import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'otp_screen.dart';

class ForgotSuccessScreen extends StatelessWidget {
  final String email;

  const ForgotSuccessScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    const Color figmaBackground = Color(0xFFF2F9F1); 
    const Color figmaLogoBg = Color(0xFFE2F3D8); 
    const Color primaryGreen = Color(0xFF327936); 

    return Scaffold(
      backgroundColor: figmaBackground, 
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Logo
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: figmaLogoBg, 
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, size: 48, color: primaryGreen), 
              ),
              const SizedBox(height: 24),
              const Text("Quên mật khẩu?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Cùng nhau bảo vệ môi trường và xây dựng tương lai xanh",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),

              // Card nội dung
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon check
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryGreen, width: 2), 
                      ),
                      child: const Icon(Icons.check, size: 32, color: primaryGreen), 
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "Kiểm tra email của bạn",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                        children: [
                          const TextSpan(text: "Chúng tôi đã gửi hướng dẫn đặt lại mật khẩu đến\n"),
                          TextSpan(text: email, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // ==============================================
                    // Đổi logic nút bấm
                    // ==============================================
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Gọi đến Class OtpScreenSingle và truyền email sang
                              builder: (context) => OtpScreenSingle(email: email), 
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen, 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Tiếp tục nhập OTP", style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),
                    // ==============================================
                    
                    const SizedBox(height: 16),
                    
                    TextButton.icon(
                      onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                      icon: const Icon(Icons.arrow_back, size: 16, color: primaryGreen), 
                      label: const Text("Quay lại đăng nhập", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500)), 
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}