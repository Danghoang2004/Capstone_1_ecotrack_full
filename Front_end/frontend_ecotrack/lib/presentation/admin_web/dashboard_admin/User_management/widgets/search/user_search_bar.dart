import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';

class UserSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isMobile;

  const UserSearchBar({
    super.key,
    required this.controller,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurfaceSoft,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        style: TextStyle(fontSize: isMobile ? 14 : 15, color: AppColors.adminTextPrimary),
        decoration: InputDecoration(
          hintText: 'Tìm kiếm theo tên hoặc email...',
          hintStyle: TextStyle(color: AppColors.adminTextSecondary.withOpacity(0.72)),
          prefixIcon: const Icon(Icons.search, color: AppColors.adminTextSecondary),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: isMobile ? 14 : 16,
          ),
        ),
      ),
    );
  }
}

