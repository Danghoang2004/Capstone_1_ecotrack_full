import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';

class UserFilterBar extends StatelessWidget {
  final String? sortOrder;
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool useColumn = constraints.maxWidth < 400;
          return useColumn ? _buildColumnLayout() : _buildRowLayout();
        },
      ),
    );
  }

  Widget _buildColumnLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSelectionRow(),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.sort,
              size: isMobile ? 16 : 18,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Sắp xếp:',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.adminTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(child: _buildDropdown()),
          ],
        ),
      ],
    );
  }

  Widget _buildRowLayout() {
    return Row(
      children: [
        _buildSelectionRow(),
        const Spacer(),
        Row(
          children: [
            Icon(
              Icons.sort,
              size: isMobile ? 16 : 18,
              color: AppColors.adminTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Sắp xếp:',
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                color: AppColors.adminTextPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: isMobile ? 150 : 180,
              child: _buildDropdown(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectionRow() {
    return Row(
      children: [
        Checkbox(
          value: selectAll,
          onChanged: (value) => onSelectAllChanged(value ?? false),
          activeColor: AppColors.adminAccent,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: () => onSelectAllChanged(!selectAll),
          child: Text(
            'Chọn tất cả',
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              color: AppColors.adminTextPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        if (hasSelectedUsers && onDeleteSelected != null) ...[
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onDeleteSelected,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Icon(
                Icons.delete_outline,
                size: isMobile ? 16 : 18,
                color: Colors.red[600],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.78),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminBorder),
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
          color: AppColors.adminTextSecondary,
          size: 20,
        ),
        hint: Text(
          'Chọn...',
          style: TextStyle(
            fontSize: isMobile ? 13 : 14,
            color: AppColors.adminTextSecondary.withOpacity(0.72),
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
                  color: AppColors.adminTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cao → Thấp',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.adminTextPrimary,
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
                  color: AppColors.adminTextSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Thấp → Cao',
                  style: TextStyle(
                    fontSize: isMobile ? 13 : 14,
                    color: AppColors.adminTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
        onChanged: onSortChanged,
        style: TextStyle(
          fontSize: isMobile ? 13 : 14,
          color: AppColors.adminTextPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
