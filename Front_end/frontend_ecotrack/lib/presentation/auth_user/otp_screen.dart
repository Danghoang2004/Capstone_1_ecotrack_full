import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:lottie/lottie.dart';
import 'package:pinput/pinput.dart';

class OtpScreenSingle extends StatefulWidget {
  final String email;
  const OtpScreenSingle({super.key, required this.email});

  @override
  State<OtpScreenSingle> createState() => _OtpScreenSingleState();
}

class _OtpScreenSingleState extends State<OtpScreenSingle> {
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _errorText;

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length < 6) {
      setState(() => _errorText = "Vui lòng nhập đủ 6 số");
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    // Bỏ comment dòng dưới khi có API thật nhé
    final result = await _authService.verifyOtp(widget.email, otp);
    
    if (!mounted) return;
    setState(() => _loading = false);

    if (result['success'] == true) {
      _showSuccessDialog();
    } else {
      setState(() => _errorText = result['message']);
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
                        fontSize: 16, // Chỉnh to lên một chút cho dễ đọc
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
                      "Xác thực OTP thành công",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
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
      // Truyền argument để biết đây là lần đầu đăng ký
      Navigator.pushNamedAndRemoveUntil(
        context,
        "/user_app",
        (route) => false,
        arguments: true, // showWelcomeDialog = true
      );
    });

    Future.delayed(const Duration(seconds: 2), () { // Giảm thời gian chờ xuống 2s cho mượt
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Thêm 3 mã màu chuẩn Figma của EcoTrack
    const Color figmaBackground = Color(0xFFF2F9F1); 
    const Color figmaLogoBg = Color(0xFFE2F3D8); 
    const Color primaryGreen = Color(0xFF327936); 

    // Theme cho ô nhập OTP
    final defaultPinTheme = PinTheme(
      width: 50,
      height: 50,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Color.fromRGBO(30, 60, 87, 1),
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300), // Viền xám nhạt
        borderRadius: BorderRadius.circular(10),
        color: Colors.white, // Nền trắng cho ô OTP
      ),
    );

    return Scaffold(
      // Đổi màu nền giao diện
      backgroundColor: figmaBackground, 
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        // Đổi màu nút back sang màu xanh đậm
        iconTheme: const IconThemeData(color: primaryGreen), 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const SizedBox(height: 10),
            // Khối Logo đồng bộ thiết kế
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: figmaLogoBg, 
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: primaryGreen, 
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Xác thực OTP",
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
            ),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 14),
                children: [
                  const TextSpan(text: "Mã xác thực đã được gửi đến email:\n"),
                  TextSpan(text: widget.email, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Đổi màu viền khi Focus vào ô OTP sang màu xanh lá chuẩn
            Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: primaryGreen, width: 1.5),
                borderRadius: BorderRadius.circular(10),
              ),
              onCompleted: (pin) => _verifyOtp(),
            ),

            const SizedBox(height: 20),
            if (_errorText != null)
              Text(
                _errorText!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),

            const SizedBox(height: 24),
            
            // Đổi màu nút bấm xác nhận
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "Xác Nhận",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 20),
            
            // Đổi màu chữ Gửi lại từ Xanh dương sang Xanh lá
            TextButton(
              onPressed: () {
                // Logic gửi lại mã
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đã gửi lại mã OTP!')),
                );
              },
              child: const Text(
                "Chưa nhận được mã? Gửi lại",
                style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}