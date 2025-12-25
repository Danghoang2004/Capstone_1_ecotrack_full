import 'package:flutter/material.dart';

class UserFilterBar extends StatelessWidget {
  final String? sortOrder; // 'high' hoặc 'low'
  final bool selectAll;
  final bool hasSelectedUsers;
  final Function(String?) onSortChanged;
  final Function(bool) onSelectAllChanged;
  final VoidCallback? onDeleteSelected;
  final bool isMobile;

  const UserFilterBar({
    super.key,
    required this.sortOrder,
    required this.selectAll,
    required this.hasSelectedUsers,
    required this.onSortChanged,
    required this.onSelectAllChanged,
    this.onDeleteSelected,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 16,
        vertical: isMobile ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Nếu không đủ không gian, chuyển sang column
          final useColumn = constraints.maxWidth < 400;

          if (useColumn) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checkbox "Chọn tất cả" + Nút Xóa
                Row(
                  children: [
                    Checkbox(
                      value: selectAll,
                      onChanged: (value) => onSelectAllChanged(value ?? false),
                      activeColor: const Color(0xFF5EAC24),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    const SizedBox(width: 4),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onSelectAllChanged(!selectAll),
                        child: Text(
                          'Chọn tất cả',
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    if (hasSelectedUsers && onDeleteSelected != null) ...[
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: onDeleteSelected,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: isMobile ? 16 : 18,
                              color: Colors.red[600],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                // Bộ lọc sắp xếp
                Row(
                  children: [
                    Icon(
                      Icons.sort,
                      size: isMobile ? 16 : 18,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Sắp xếp:',
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 10 : 12,
                          vertical: isMobile ? 6 : 8,
                        ),
                        child: DropdownButton<String?>(
                          value: sortOrder,
                          underline: const SizedBox(),
                          isDense: true,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                          hint: Text(
                            'Chọn...',
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 14,
                              color: Colors.grey[500],
                            ),
                          ),
                          items: [
                            DropdownMenuItem<String?>(
                              value: 'high',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_downward,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cao → Thấp',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            DropdownMenuItem<String?>(
                              value: 'low',
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_upward,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Thấp → Cao',
                                    style: TextStyle(
                                      fontSize: isMobile ? 13 : 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onChanged: onSortChanged,
                          style: TextStyle(
                            fontSize: isMobile ? 13 : 14,
                            color: Colors.grey[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          // Nếu đủ không gian, dùng Row
          return Row(
            children: [
              // Checkbox "Chọn tất cả" + Nút Xóa
              Row(
                children: [
                  Checkbox(
                    value: selectAll,
                    onChanged: (value) => onSelectAllChanged(value ?? false),
                    activeColor: const Color(0xFF5EAC24),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 4),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => onSelectAllChanged(!selectAll),
                      child: Text(
                        'Chọn tất cả',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  if (hasSelectedUsers && onDeleteSelected != null) ...[
                    const SizedBox(width: 12),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onDeleteSelected,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.red[300]!),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: isMobile ? 16 : 18,
                            color: Colors.red[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Spacer(),
              // Bộ lọc sắp xếp
              Row(
                children: [
                  Icon(
                    Icons.sort,
                    size: isMobile ? 16 : 18,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sắp xếp:',
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 10 : 12,
                      vertical: isMobile ? 6 : 8,
                    ),
                    child: DropdownButton<String?>(
                      value: sortOrder,
                      underline: const SizedBox(),
                      isDense: true,
                      icon: Icon(
                        Icons.arrow_drop_down,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      hint: Text(
                        'Chọn...',
                        style: TextStyle(
                          fontSize: isMobile ? 13 : 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      items: [
                        DropdownMenuItem<String?>(
                          value: 'high',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_downward,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Cao → Thấp',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                        DropdownMenuItem<String?>(
                          value: 'low',
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_upward,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Thấp → Cao',
                                style: TextStyle(
                                  fontSize: isMobile ? 13 : 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onChanged: onSortChanged,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        color: Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

