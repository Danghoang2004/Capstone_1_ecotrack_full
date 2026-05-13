import 'package:flutter/material.dart';

class EnvironmentUserManagementHeader extends StatelessWidget {
  final bool isMobile;
  final bool isTablet;
  final int totalUsers;

  const EnvironmentUserManagementHeader({
    super.key,
    required this.isMobile,
    required this.isTablet,
    required this.totalUsers,
  });

  Widget _buildCountBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4D8),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFF5EAC24).withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.groups_2_outlined,
            size: 16,
            color: Color(0xFF3F7E14),
          ),
          const SizedBox(width: 6),
          Text(
            '$totalUsers tài khoản',
            style: const TextStyle(
              color: Color(0xFF2F5F11),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isMobile
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Tài Khoản Môi Trường',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _buildCountBadge(),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Quản lý danh sách nhân sự môi trường, quyền truy cập và trạng thái tài khoản',
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
                      'Tài Khoản Môi Trường',
                      style: TextStyle(
                        fontSize: isTablet ? 24 : 28,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A1A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Quản lý danh sách nhân sự môi trường, quyền truy cập và trạng thái tài khoản',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              _buildCountBadge(),
            ],
          );
  }
}
