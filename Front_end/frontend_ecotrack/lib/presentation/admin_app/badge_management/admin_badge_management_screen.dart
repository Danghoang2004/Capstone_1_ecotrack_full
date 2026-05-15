import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/admin_badge_service.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';

class AdminBadgeManagementScreen extends StatefulWidget {
  const AdminBadgeManagementScreen({super.key});

  @override
  State<AdminBadgeManagementScreen> createState() =>
      _AdminBadgeManagementScreenState();
}

class _AdminBadgeManagementScreenState
    extends State<AdminBadgeManagementScreen> {
  final AdminBadgeService _service = AdminBadgeService();
  final ScrollController _tableScrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const int _itemsPerPage = 7;
  static const Duration _refreshInterval = Duration(seconds: 45);

  List<BadgeModel> _badges = [];
  final Set<int> _selectedBadgeIds = <int>{};
  bool _loading = true;
  bool _isRefreshing = false;
  DateTime? _lastSyncedAt;
  Timer? _refreshTimer;
  String? _error;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _loadBadges();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tableScrollController.dispose();
    _searchController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadBadges(silent: true);
    });
  }

  Future<void> _loadBadges({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;
    setState(() => _isRefreshing = true);
    try {
      final badges = await _service.getAllBadges();
      if (!mounted) return;
      setState(() {
        _badges = badges;
        _selectedBadgeIds.clear();
        _currentPage = 1;
        _loading = false;
        _error = null;
        _lastSyncedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  List<BadgeModel> _filterBadges() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _badges;

    return _badges.where((badge) {
      return badge.badgeName.toLowerCase().contains(query) ||
          badge.description.toLowerCase().contains(query) ||
          badge.requirement.toLowerCase().contains(query) ||
          badge.badgeId.toString().contains(query);
    }).toList();
  }

  List<BadgeModel> _getPageItems(List<BadgeModel> source, int safePage) {
    final start = (safePage - 1) * _itemsPerPage;
    return source.skip(start).take(_itemsPerPage).toList();
  }

  void _setPage(int page, int totalPages) {
    setState(() {
      _currentPage = page.clamp(1, totalPages);
    });
  }

  BadgeModel _badgeFromResponse(Map<String, dynamic> response) {
    final data = response['data'];
    if (data is Map<String, dynamic>) {
      final json = Map<String, dynamic>.from(data);
      final rawIcon = (json['iconUrl'] ?? '').toString();
      json['iconUrl'] = _service.apiClient.buildImageUrl(rawIcon);
      return BadgeModel.fromJson(json);
    }
    throw Exception('Phản hồi từ server không hợp lệ');
  }

  void _upsertBadge(BadgeModel badge, {required bool isEdit}) {
    setState(() {
      final index = _badges.indexWhere((item) => item.badgeId == badge.badgeId);
      if (index >= 0) {
        _badges[index] = badge;
      } else if (!isEdit) {
        _badges.add(badge);
      }
      _badges.sort((a, b) => a.badgeId.compareTo(b.badgeId));
      _currentPage = 1;
    });
  }

  bool _isBadgeSelected(int badgeId) {
    return _selectedBadgeIds.contains(badgeId);
  }

  void _toggleBadgeSelection(int badgeId, bool selected) {
    setState(() {
      if (selected) {
        _selectedBadgeIds.add(badgeId);
      } else {
        _selectedBadgeIds.remove(badgeId);
      }
    });
  }

  void _toggleSelectAll(List<BadgeModel> badges, bool selected) {
    setState(() {
      if (selected) {
        _selectedBadgeIds.addAll(badges.map((badge) => badge.badgeId));
      } else {
        _selectedBadgeIds.removeAll(badges.map((badge) => badge.badgeId));
      }
    });
  }

  Future<void> _deleteBadgesByIds(List<int> badgeIds) async {
    try {
      for (final badgeId in badgeIds) {
        await _service.deleteBadge(badgeId);
      }
      if (!mounted) return;
      setState(() {
        _selectedBadgeIds.removeAll(badgeIds);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            badgeIds.length == 1
                ? 'Xóa huy hiệu thành công'
                : 'Xóa ${badgeIds.length} huy hiệu thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );
      await _loadBadges();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showBadgeDialog({BadgeModel? badge}) {
    final isEdit = badge != null;
    final nameController = TextEditingController(text: badge?.badgeName ?? '');
    final descController = TextEditingController(
      text: badge?.description ?? '',
    );
    final iconController = TextEditingController(text: badge?.iconUrl ?? '');
    final reqController = TextEditingController(text: badge?.requirement ?? '');
    final pointsController = TextEditingController(
      text: badge?.pointsRequired.toString() ?? '0',
    );
    Uint8List? selectedImageBytes;
    String? selectedImageName;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) {
        final dialogMaxWidth = MediaQuery.of(ctx).size.width * 0.9;
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                isEdit ? 'Chỉnh sửa huy hiệu' : 'Thêm huy hiệu mới',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SizedBox(
                width: dialogMaxWidth > 560 ? 560 : dialogMaxWidth,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tên huy hiệu'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          hintText: 'Nhập tên huy hiệu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Mô tả'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'Nhập mô tả huy hiệu',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Ảnh huy hiệu'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                            withData: true,
                          );
                          if (result != null && result.files.isNotEmpty) {
                            final file = result.files.first;
                            if (file.bytes != null) {
                              setDialogState(() {
                                selectedImageBytes = file.bytes;
                                selectedImageName = file.name;
                              });
                            }
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.adminSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.adminBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.upload_file,
                                color: AppColors.adminAccentDeep,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedImageName ??
                                      (badge?.iconUrl.isNotEmpty == true
                                          ? 'Đang dùng ảnh hiện tại'
                                          : 'Bấm để chọn file ảnh'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('URL icon (dự phòng nếu không upload file)'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: iconController,
                        decoration: const InputDecoration(
                          hintText: 'https://example.com/icon.png',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Yêu cầu'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reqController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Nhập yêu cầu đạt mốc',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('Điểm yêu cầu'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: pointsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(ctx),
                  child: const Text(
                    'Hủy',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          try {
                            setDialogState(() => isSaving = true);
                            final badgeName = nameController.text.trim();
                            final description = descController.text.trim();
                            final requirement = reqController.text.trim();
                            final pointsRequired =
                                int.tryParse(pointsController.text) ?? 0;

                            Map<String, dynamic> response;
                            if (selectedImageBytes != null &&
                                selectedImageName != null) {
                              if (isEdit) {
                                response = await _service.updateBadgeWithImage(
                                  badgeId: badge.badgeId,
                                  badgeName: badgeName,
                                  description: description,
                                  requirement: requirement,
                                  pointsRequired: pointsRequired,
                                  imageBytes: selectedImageBytes!,
                                  imageFileName: selectedImageName!,
                                );
                              } else {
                                response = await _service.createBadgeWithImage(
                                  badgeName: badgeName,
                                  description: description,
                                  requirement: requirement,
                                  pointsRequired: pointsRequired,
                                  imageBytes: selectedImageBytes!,
                                  imageFileName: selectedImageName!,
                                );
                              }
                            } else {
                              final iconUrl = iconController.text.trim();
                              if (isEdit) {
                                response = await _service.updateBadge(
                                  badgeId: badge.badgeId,
                                  badgeName: badgeName,
                                  description: description,
                                  iconUrl: iconUrl,
                                  requirement: requirement,
                                  pointsRequired: pointsRequired,
                                );
                              } else {
                                response = await _service.createBadge(
                                  badgeName: badgeName,
                                  description: description,
                                  iconUrl: iconUrl,
                                  requirement: requirement,
                                  pointsRequired: pointsRequired,
                                );
                              }
                            }

                            if (!mounted) return;
                            final savedBadge = _badgeFromResponse(response);
                            _upsertBadge(savedBadge, isEdit: isEdit);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEdit
                                      ? 'Cập nhật huy hiệu thành công'
                                      : 'Tạo huy hiệu thành công',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                            if (!mounted) return;
                            Navigator.pop(ctx);
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Lỗi: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } finally {
                            if (mounted) {
                              setDialogState(() => isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminAccent,
                  ),
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'Lưu thay đổi' : 'Thêm',
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _previewBadgeImage(BadgeModel badge) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(badge.badgeName),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (badge.iconUrl.isEmpty)
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppColors.adminSurfaceMuted,
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    size: 120,
                    color: AppColors.adminAccentDeep,
                  ),
                )
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    badge.iconUrl,
                    width: 280,
                    height: 280,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: AppColors.adminSurfaceMuted,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        size: 120,
                        color: AppColors.adminAccentDeep,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                badge.description.isEmpty ? 'Chưa có mô tả' : badge.description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.adminTextSecondary),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.adminAccent,
            ),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteBadge(int badgeId) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool confirmDelete = false;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Xác nhận xóa'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bạn có chắc chắn muốn xóa huy hiệu này không?'),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: confirmDelete,
                    onChanged: (value) {
                      setDialogState(() {
                        confirmDelete = value ?? false;
                      });
                    },
                    title: const Text(
                      'Tôi hiểu thao tác này không thể hoàn tác',
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    dense: true,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: !confirmDelete
                      ? null
                      : () async {
                          final shouldDelete =
                              await showDialog<bool>(
                                context: context,
                                builder: (confirmCtx) => AlertDialog(
                                  title: const Text('Xác nhận lần cuối'),
                                  content: const Text(
                                    'Huy hiệu sẽ bị xóa khỏi hệ thống. Bạn có muốn tiếp tục không?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(confirmCtx, false),
                                      child: const Text('Không'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(confirmCtx, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: const Text(
                                        'Xóa ngay',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;

                          if (!shouldDelete) return;

                          if (!mounted) return;
                          Navigator.pop(ctx);
                          await _deleteBadgesByIds([badgeId]);
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text(
                    'Xóa',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteSelectedBadges() async {
    final selectedBadges = _badges
        .where((badge) => _selectedBadgeIds.contains(badge.badgeId))
        .toList();

    if (selectedBadges.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn ít nhất một huy hiệu để xóa'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (confirmCtx) => AlertDialog(
            title: const Text('Xác nhận xóa hàng loạt'),
            content: Text(
              'Bạn có chắc chắn muốn xóa ${selectedBadges.length} huy hiệu đã chọn không?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(confirmCtx, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(confirmCtx, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text(
                  'Xóa ngay',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) return;

    if (!mounted) return;
    await _deleteBadgesByIds(
      selectedBadges.map((badge) => badge.badgeId).toList(),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() => _currentPage = 1),
      decoration: InputDecoration(
        hintText: 'Tìm kiếm huy hiệu...',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: AppColors.adminSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.adminBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.adminAccent,
            width: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionToolbar(List<BadgeModel> badges) {
    final allSelected =
        badges.isNotEmpty &&
        badges.every((badge) => _selectedBadgeIds.contains(badge.badgeId));
    final someSelected = badges.any(
      (badge) => _selectedBadgeIds.contains(badge.badgeId),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 680;
          final selectedCount = _selectedBadgeIds.length;

          final selectAll = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Checkbox(
                tristate: true,
                value: allSelected ? true : (someSelected ? null : false),
                onChanged: (_) => _toggleSelectAll(badges, !allSelected),
              ),
              const SizedBox(width: 4),
              Text(
                'Chọn tất cả kết quả',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.adminTextPrimary,
                ),
              ),
            ],
          );

          final deleteButton = ElevatedButton.icon(
            onPressed: selectedCount == 0 ? null : _deleteSelectedBadges,
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text('Xóa đã chọn ($selectedCount)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          if (isCompact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [selectAll, const SizedBox(height: 12), deleteButton],
            );
          }

          return Row(
            children: [
              selectAll,
              const Spacer(),
              Text(
                '$selectedCount mục đã chọn',
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              deleteButton,
            ],
          );
        },
      ),
    );
  }

  Widget _tableCell(
    String value,
    double width, {
    FontWeight fontWeight = FontWeight.w500,
    int maxLines = 1,
    Color? color,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        value,
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: fontWeight,
          color: color ?? AppColors.adminTextPrimary,
        ),
      ),
    );
  }

  Widget _tableActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Widget _buildBadgeCheckbox(BadgeModel badge) {
    return Checkbox(
      value: _isBadgeSelected(badge.badgeId),
      onChanged: (value) {
        _toggleBadgeSelection(badge.badgeId, value ?? false);
      },
    );
  }

  Widget _buildBadgeTable(List<BadgeModel> badges) {
    const sidePadding = 8.0;
    const selectCol = 52.0;
    const badgeCol = 290.0;
    const descCol = 220.0;
    const reqCol = 210.0;
    const pointsCol = 120.0;
    const idCol = 80.0;
    const actionCol = 168.0;

    final tableWidth = math.max(
      MediaQuery.of(context).size.width,
      sidePadding * 2 +
          selectCol +
          badgeCol +
          descCol +
          reqCol +
          pointsCol +
          idCol +
          actionCol,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Scrollbar(
          controller: _tableScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          interactive: true,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            controller: _tableScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    color: const Color(0xFFF1F3F6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: sidePadding,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: selectCol,
                          child: Checkbox(
                            tristate: true,
                            value: badges.isEmpty
                                ? false
                                : (badges.every(
                                        (badge) =>
                                            _isBadgeSelected(badge.badgeId),
                                      )
                                      ? true
                                      : (badges.any(
                                              (badge) => _isBadgeSelected(
                                                badge.badgeId,
                                              ),
                                            )
                                            ? null
                                            : false)),
                            onChanged: (_) {
                              _toggleSelectAll(
                                badges,
                                !badges.every(
                                  (badge) => _isBadgeSelected(badge.badgeId),
                                ),
                              );
                            },
                          ),
                        ),
                        _TableHeaderCell('Huy hiệu', badgeCol),
                        _TableHeaderCell('Mô tả', descCol),
                        _TableHeaderCell('Yêu cầu', reqCol),
                        _TableHeaderCell('Điểm', pointsCol),
                        _TableHeaderCell('Mã', idCol),
                        _TableHeaderCell('Thao tác', actionCol),
                      ],
                    ),
                  ),
                  ...badges.asMap().entries.map((entry) {
                    final index = entry.key;
                    final badge = entry.value;
                    final isLast = index == badges.length - 1;
                    final isSelected = _isBadgeSelected(badge.badgeId);

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: sidePadding,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.adminAccentSoft.withOpacity(0.22)
                            : index.isEven
                            ? AppColors.adminSurface
                            : const Color(0xFFFCFDFC),
                        border: isLast
                            ? null
                            : const Border(
                                bottom: BorderSide(
                                  color: AppColors.adminBorder,
                                ),
                              ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: selectCol,
                            child: Center(child: _buildBadgeCheckbox(badge)),
                          ),
                          SizedBox(
                            width: badgeCol,
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(17),
                                    color: AppColors.adminSurfaceMuted,
                                  ),
                                  child: badge.iconUrl.isEmpty
                                      ? const Icon(
                                          Icons.shield_outlined,
                                          size: 18,
                                          color: AppColors.adminAccentDeep,
                                        )
                                      : ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            17,
                                          ),
                                          child: Image.network(
                                            badge.iconUrl,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) {
                                              return const Icon(
                                                Icons.shield_outlined,
                                                size: 18,
                                                color:
                                                    AppColors.adminAccentDeep,
                                              );
                                            },
                                          ),
                                        ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    badge.badgeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _tableCell(
                            badge.description.isEmpty
                                ? 'Chưa có mô tả'
                                : badge.description,
                            descCol,
                            color: AppColors.adminTextSecondary,
                          ),
                          _tableCell(
                            badge.requirement.isEmpty
                                ? 'Chưa cập nhật yêu cầu'
                                : badge.requirement,
                            reqCol,
                            color: AppColors.adminTextSecondary,
                          ),
                          SizedBox(
                            width: pointsCol,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.adminAccentSoft,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  '${badge.pointsRequired} điểm',
                                  style: const TextStyle(
                                    color: AppColors.adminAccentDeep,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          _tableCell('#${badge.badgeId}', idCol),
                          SizedBox(
                            width: actionCol,
                            child: Row(
                              children: [
                                _tableActionButton(
                                  icon: Icons.visibility_outlined,
                                  color: const Color(0xFF2196F3),
                                  onPressed: () => _previewBadgeImage(badge),
                                ),
                                const SizedBox(width: 8),
                                _tableActionButton(
                                  icon: Icons.edit_note,
                                  color: AppColors.adminTextSecondary,
                                  onPressed: () =>
                                      _showBadgeDialog(badge: badge),
                                ),
                                const SizedBox(width: 8),
                                _tableActionButton(
                                  icon: Icons.delete_outline,
                                  color: Colors.redAccent,
                                  onPressed: () => _deleteBadge(badge.badgeId),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPagination({
    required int safePage,
    required int totalPages,
    required int totalItems,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 10,
          spacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: constraints.maxWidth > 560
                  ? constraints.maxWidth - 250
                  : constraints.maxWidth,
              child: Text(
                'Trang $safePage/$totalPages',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: safePage == 1
                      ? null
                      : () => _setPage(safePage - 1, totalPages),
                  icon: const Icon(Icons.chevron_left),
                  label: const Text('Trước'),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: safePage >= totalPages
                      ? null
                      : () => _setPage(safePage + 1, totalPages),
                  icon: const Icon(Icons.chevron_right),
                  label: const Text('Sau'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filterBadges();
    final totalPages = math.max(1, (filtered.length / _itemsPerPage).ceil());
    final safePage = _currentPage.clamp(1, totalPages);
    final pageItems = _getPageItems(filtered, safePage);

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: math.max(
                  1320,
                  MediaQuery.of(context).size.width - 160,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _AdminAccentChip(),
                          SizedBox(height: 10),
                          Text(
                            'Quản Lý Huy Hiệu',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.8,
                              color: AppColors.adminTextPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Tạo, chỉnh sửa và quản trị hệ thống huy hiệu',
                            style: TextStyle(
                              fontSize: 17,
                              color: AppColors.adminTextSecondary,
                            ),
                          ),
                        ],
                      ),

                      ElevatedButton.icon(
                        onPressed: () => _showBadgeDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Tạo huy hiệu mới'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.adminAccentDeep,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.adminAccentDeep.withOpacity(
                            0.28,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),
                  // search & content
                  _buildSearchBar(),
                  const SizedBox(height: 16),

                  if (filtered.isNotEmpty) ...[
                    _buildSelectionToolbar(filtered),
                    const SizedBox(height: 16),
                  ],

                  // Adaptive content area: table for wide screens, stacked cards for narrow
                  SizedBox(
                    height: math.min(
                      MediaQuery.of(context).size.height * 0.74,
                      880,
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Lỗi: $_error'),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadBadges,
                                  child: const Text('Thử lại'),
                                ),
                              ],
                            ),
                          )
                        : filtered.isEmpty
                        ? const Center(child: Text('Không có huy hiệu nào'))
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              const breakpoint = 900.0;
                              final isNarrow =
                                  constraints.maxWidth < breakpoint;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: isNarrow
                                        ? _buildCardList(pageItems)
                                        : _buildBadgeTable(pageItems),
                                  ),

                                  if (filtered.length > _itemsPerPage) ...[
                                    const SizedBox(height: 12),
                                    _buildPagination(
                                      safePage: safePage,
                                      totalPages: totalPages,
                                      totalItems: filtered.length,
                                    ),
                                  ],
                                ],
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardList(List<BadgeModel> badges) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adminBorder),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
        itemCount: badges.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final badge = badges[index];
          final isSelected = _isBadgeSelected(badge.badgeId);
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.adminAccentSoft.withOpacity(0.22)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 40,
                  child: Center(child: _buildBadgeCheckbox(badge)),
                ),
                const SizedBox(width: 4),

                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.adminSurfaceMuted,
                  ),
                  child: badge.iconUrl.isEmpty
                      ? const Icon(
                          Icons.shield_outlined,
                          color: AppColors.adminAccentDeep,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            badge.iconUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shield_outlined,
                              color: AppColors.adminAccentDeep,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                // Main info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badge.badgeName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.adminAccentSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#${badge.badgeId}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.adminAccentDeep,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badge.description.isEmpty
                            ? 'Chưa có mô tả'
                            : badge.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              badge.requirement.isEmpty
                                  ? 'Chưa cập nhật yêu cầu'
                                  : badge.requirement,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.adminTextSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.adminAccentSoft,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${badge.pointsRequired} điểm',
                              style: const TextStyle(
                                color: AppColors.adminAccentDeep,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Actions
                Column(
                  children: [
                    _tableActionButton(
                      icon: Icons.visibility_outlined,
                      color: const Color(0xFF2196F3),
                      onPressed: () => _previewBadgeImage(badge),
                    ),
                    const SizedBox(height: 8),
                    _tableActionButton(
                      icon: Icons.edit_note,
                      color: AppColors.adminTextSecondary,
                      onPressed: () => _showBadgeDialog(badge: badge),
                    ),
                    const SizedBox(height: 8),
                    _tableActionButton(
                      icon: Icons.delete_outline,
                      color: Colors.redAccent,
                      onPressed: () => _deleteBadge(badge.badgeId),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String title;
  final double width;

  const _TableHeaderCell(this.title, this.width);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: AppColors.adminTextSecondary,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _AdminAccentChip extends StatelessWidget {
  const _AdminAccentChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.adminAccentSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'EcoTrack Admin',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppColors.adminAccentDeep,
        ),
      ),
    );
  }
}
