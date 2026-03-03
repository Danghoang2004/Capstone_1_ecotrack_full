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
                      "Xác thực OTP thành công",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
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

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
        border: Border.all(color: const Color.fromRGBO(234, 239, 243, 1)),
        borderRadius: BorderRadius.circular(10),
        color: const Color.fromRGBO(245, 248, 250, 1),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          'Xác Thực Email',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Xác thực OTP",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Mã xác thực đã được gửi đến email:\n${widget.email}",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),

            const SizedBox(height: 32),

            // Pinput Widget (Cần cài package pinput)
            Pinput(
              length: 6,
              controller: _otpController,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.circular(8),
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

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Xác Nhận",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                // Logic gửi lại mã
              },
              child: const Text(
                "Chưa nhận được mã? Gửi lại",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
