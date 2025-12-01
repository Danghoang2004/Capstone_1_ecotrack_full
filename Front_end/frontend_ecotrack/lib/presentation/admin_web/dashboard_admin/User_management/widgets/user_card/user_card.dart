import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'stat_item.dart';
import 'action_button.dart';
import '../../../../../common/formatNumber/format_number.dart';

class UserCard extends StatelessWidget {
  final Map<String, dynamic> user;
  final bool isMobile;
  final bool isTablet;
  final bool isSelected;
  final Function(bool) onSelectionChanged;
  final VoidCallback? onToggleSelection; // Callback để toggle selection
  final VoidCallback? onEdit; // Callback để mở dialog chỉnh sửa
  final VoidCallback? onDelete; // Callback để xóa user

  const UserCard({
    super.key,
    required this.user,
    required this.isMobile,
    required this.isTablet,
    this.isSelected = false,
    required this.onSelectionChanged,
    this.onToggleSelection,
    this.onEdit,
    this.onDelete,
  });

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}';
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  Widget _buildRankBadge(int rank) {
    if (rank == 1) {
      return SvgPicture.asset('assets/icons/top1.svg', width: 24, height: 24);
    } else if (rank == 2) {
      return SvgPicture.asset('assets/icons/top2.svg', width: 24, height: 24);
    } else if (rank == 3) {
      return SvgPicture.asset('assets/icons/top3.svg', width: 24, height: 24);
    } else {
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isActive = user['status'] == 'active';
    final rank = user['rank'] ?? 0;

    if (isMobile) {
      return _buildMobileCard(isActive, rank);
    } else {
      return _buildDesktopCard(isActive, rank);
    }
  }

  // Card cho Mobile
  Widget _buildMobileCard(bool isActive, int rank) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (onToggleSelection != null) {
            onToggleSelection!();
          } else {
            onSelectionChanged(!isSelected);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Row 1: Checkbox + Avatar + Tên + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (value) {
                        if (onToggleSelection != null) {
                          onToggleSelection!();
                        } else {
                          onSelectionChanged(value ?? false);
                        }
                      },
                      activeColor: const Color(0xFF5EAC24),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5EAC24).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child:
                              user['avatarUrl'] != null &&
                                  user['avatarUrl'].toString().isNotEmpty
                              ? ClipOval(
                                  child: Image.network(
                                    user['avatarUrl'],
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) => Center(
                                          child: Text(
                                            _getInitials(user['name']),
                                            style: const TextStyle(
                                              color: Color(0xFF5EAC24),
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(user['name']),
                                    style: const TextStyle(
                                      color: Color(0xFF5EAC24),
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                user['email'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {}, // Ngăn event bubble lên parent
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Không hoạt động',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Row 2: Rank Badge + Points
              Row(
                children: [
                  _buildRankBadge(rank),
                  const SizedBox(width: 8),
                  Text(
                    '${FormatNumber.formatPoints(user['points'])} điểm',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const Spacer(),
                  StatItem(
                    label: 'Báo cáo',
                    value: '${user['reports']}',
                    icon: Icons.location_on_outlined,
                    iconColor: Colors.redAccent,
                    compact: true,
                  ),
                  const SizedBox(width: 16),
                  StatItem(
                    label: 'Chiến dịch',
                    value: '${user['campaigns']}',
                    icon: Icons.flag_outlined,
                    iconColor: Colors.blueAccent,
                    compact: true,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Row 3: Action Buttons
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {}, // Ngăn event bubble lên parent
                      child: OutlinedButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Sửa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {}, // Ngăn event bubble lên parent
                      child: OutlinedButton.icon(
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Xóa'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[400],
                          side: BorderSide(color: Colors.red.shade200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Card cho Desktop/Tablet
  Widget _buildDesktopCard(bool isActive, int rank) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          if (onToggleSelection != null) {
            onToggleSelection!();
          } else {
            onSelectionChanged(!isSelected);
          }
        },
        behavior: HitTestBehavior.translucent,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? 16 : 24,
            vertical: isTablet ? 16 : 20,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Checkbox
              SizedBox(
                height: 24,
                width: 24,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    if (onToggleSelection != null) {
                      onToggleSelection!();
                    } else {
                      onSelectionChanged(value ?? false);
                    }
                  },
                  activeColor: const Color(0xFF5EAC24),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const SizedBox(width: 8),
              // Nhóm trái: Avatar + Tên + Điểm
              Expanded(
                flex: isTablet ? 2 : 3,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF5EAC24).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child:
                          user['avatarUrl'] != null &&
                              user['avatarUrl'].toString().isNotEmpty
                          ? ClipOval(
                              child: Image.network(
                                user['avatarUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Text(
                                        _getInitials(user['name']),
                                        style: const TextStyle(
                                          color: Color(0xFF5EAC24),
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              ),
                            )
                          : Center(
                              child: Text(
                                _getInitials(user['name']),
                                style: const TextStyle(
                                  color: Color(0xFF5EAC24),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user['name'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user['email'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[500],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (!isTablet) ...[
                const SizedBox(width: 24),
                SizedBox(
                  width: 120,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildRankBadge(rank),
                          const SizedBox(width: 8),
                          Text(
                            '${FormatNumber.formatPoints(user['points'])} điểm',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              // Nhóm phải: Stats + Status + Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isTablet) ...[
                    StatItem(
                      label: 'Báo cáo',
                      value: '${user['reports']}',
                      icon: Icons.location_on_outlined,
                      iconColor: Colors.redAccent,
                    ),
                    const SizedBox(width: 24),
                    StatItem(
                      label: 'Chiến dịch',
                      value: '${user['campaigns']}',
                      icon: Icons.flag_outlined,
                      iconColor: Colors.blueAccent,
                    ),
                    const SizedBox(width: 40),
                  ],
                  GestureDetector(
                    onTap: () {}, // Ngăn event bubble lên parent
                    child: Container(
                      width: isTablet ? 100 : 130,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.black : Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Hoạt động' : 'Không hoạt động',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {}, // Ngăn event bubble lên parent
                    child: ActionButton(
                      icon: Icons.edit_outlined,
                      onTap: onEdit ?? () {},
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {}, // Ngăn event bubble lên parent
                    child: ActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.red[400],
                      onTap: onDelete ?? () {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
