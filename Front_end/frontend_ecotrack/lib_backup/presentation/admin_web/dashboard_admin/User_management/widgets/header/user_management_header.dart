import 'package:flutter/material.dart';

class UserManagementHeader extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;

  const UserManagementHeader({
    super.key,
    required this.isMobile,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quản Lý Người Dùng',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý thông tin người dùng, điểm thưởng và hoạt động',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quản Lý Người Dùng',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý thông tin người dùng, điểm thưởng và hoạt động',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
  }
}

