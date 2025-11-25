import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:lottie/lottie.dart'; // 1. Đừng quên import Lottie

class OtpScreenSingle extends StatefulWidget {
  final String email;
  const OtpScreenSingle({super.key, required this.email});

  @override
  State<OtpScreenSingle> createState() => _OtpScreenSingleState();
}

class _OtpScreenSingleState extends State<OtpScreenSingle> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _errorText;

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
      Navigator.pushNamedAndRemoveUntil(context, "/user_app", (route) => false);
    });

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text;

    if (otp.length != 6) {
      setState(() => _errorText = "Vui lòng nhập đủ 6 số OTP");
      return;
    }

    setState(() {
      _loading = true;
      _errorText = null;
    });

    final ok = await _authService.verifyOtp(widget.email, otp);

    setState(() => _loading = false);

    if (ok) {
      _showSuccessDialog();
    } else {
      setState(() => _errorText = "OTP không đúng hoặc đã hết hạn");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Xác thực OTP"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Nhập OTP đã gửi tới Email:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_focusNode),
              child: SizedBox(
                height: 60,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    String digit = "";
                    if (_otpController.text.length > index) {
                      digit = _otpController.text[index];
                    }

                    return Container(
                      width: 40,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        digit,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            SizedBox(
              height: 0,
              width: 0,
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: _otpController,
                  focusNode: _focusNode,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.length <= 6) {
                      setState(() {
                        _errorText = null;
                      });
                    }
                  },
                ),
              ),
            ),

            const SizedBox(height: 10),

            if (_errorText != null)
              Text(
                _errorText!,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _verify,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 90, 207, 90),
                foregroundColor: const Color.fromARGB(255, 5, 5, 5),
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.deepPurple)
                  : const Text("Xác nhận OTP", style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }
}
