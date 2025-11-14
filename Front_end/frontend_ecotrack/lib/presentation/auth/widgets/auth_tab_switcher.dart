import 'package:flutter/material.dart';

class AuthTabSwitcher extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onLoginTap;
  final VoidCallback onRegisterTap;

  const AuthTabSwitcher({
    super.key,
    required this.isLogin,
    required this.onLoginTap,
    required this.onRegisterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onLoginTap,
              child: Container(
                alignment: Alignment.center,
                height: 40,
                decoration: BoxDecoration(
                  color: isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("Đăng nhập"),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: onRegisterTap,
              child: Container(
                alignment: Alignment.center,
                height: 40,
                decoration: BoxDecoration(
                  color: !isLogin ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text("Đăng ký"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
