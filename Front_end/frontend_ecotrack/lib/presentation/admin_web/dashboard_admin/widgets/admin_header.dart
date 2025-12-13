import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminHeader extends StatelessWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70, // Giống PartnerHeader
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // --- PHẦN LOGO GIỐNG PARTNER ---
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF5EAC24),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              // Nếu bạn chưa có file svg, hãy thay child này bằng Icon(Icons.eco, color: Colors.white)
              child: SvgPicture.asset(
                'assets/images/Logo.svg',
                width: 30,
                height: 30,
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Title & Subtitle
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EcoTrack',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                'Admin Portal', // Đổi tên cho đúng ngữ cảnh Admin
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          const Spacer(),

          // --- PHẦN ACTION CỦA ADMIN CŨ (Giữ lại logic cũ) ---
          const Icon(Icons.notifications_outlined, color: Colors.grey),
          const SizedBox(width: 20),
          const CircleAvatar(
            backgroundColor: Colors.orange,
            radius: 18,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }
}
