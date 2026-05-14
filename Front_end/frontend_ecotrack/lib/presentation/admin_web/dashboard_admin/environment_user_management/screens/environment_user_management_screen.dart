import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/widgets/filter/user_filter_bar.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/widgets/search/user_search_bar.dart';
import 'package:frontend_ecotrack/presentation/admin_web/dashboard_admin/User_management/widgets/user_card/user_card.dart';
import '../controllers/environment_user_management_controller.dart';
import '../widgets/edit_environment_user_dialog/edit_environment_user_dialog.dart';
import '../widgets/header/environment_user_management_header.dart';

class EnvironmentUserManagementScreen extends StatefulWidget {
  const EnvironmentUserManagementScreen({super.key});

  @override
  State<EnvironmentUserManagementScreen> createState() =>
      _EnvironmentUserManagementScreenState();
}

class _EnvironmentUserManagementScreenState
    extends State<EnvironmentUserManagementScreen> {
  late final EnvironmentUserManagementController controller =
      EnvironmentUserManagementController();
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  DateTime? _lastSyncedAt;

  static const Duration _refreshInterval = Duration(seconds: 48);

  @override
  void initState() {
    super.initState();
    controller.searchController.addListener(_onSearchChanged);
    _loadUsers();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    controller.searchController.removeListener(_onSearchChanged);
    controller.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    if (!mounted || _isRefreshing) {
      return;
    }
    setState(() => _isRefreshing = true);
    try {
      await controller.loadUsers();
      if (mounted) {
        setState(() {
          _lastSyncedAt = DateTime.now();
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  void _onSearchChanged() {
    setState(() {
      controller.filterUsers();
    });
  }

  Future<void> _handleDeleteSelected() async {
    if (controller.selectedUserIds.isEmpty) return;

    final count = controller.selectedUserIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa $count tài khoản môi trường đã chọn? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await controller.deleteSelectedUsers();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã xóa $count tài khoản môi trường thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: Text(
            'Bạn có chắc chắn muốn xóa tài khoản môi trường "${user['name']}"? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await controller.deleteUser(user['id'] as int);
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã xóa tài khoản môi trường thành công'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Lỗi khi xóa: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 1400,
              ),
              margin: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 12 : 20,
              ),
              decoration: BoxDecoration(
                color: AppColors.adminSurface,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.adminBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 24,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    EnvironmentUserManagementHeader(
                      isMobile: isMobile,
                      isTablet: isTablet,
                      totalUsers: controller.users.length,
                    ),
                    SizedBox(height: isMobile ? 18 : 28),
                    UserSearchBar(
                      controller: controller.searchController,
                      isMobile: isMobile,
                    ),
                    SizedBox(height: isMobile ? 14 : 20),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: UserFilterBar(
                              sortOrder: controller.sortOrder,
                              selectAll: controller.isAllSelected,
                              hasSelectedUsers: controller.hasSelectedUsers,
                              onSortChanged: (order) {
                                setState(() {
                                  controller.setSortOrder(order);
                                });
                              },
                              onSelectAllChanged: (value) {
                                setState(() {
                                  if (value) {
                                    controller.selectAll();
                                  } else {
                                    controller.deselectAll();
                                  }
                                });
                              },
                              onDeleteSelected: () async {
                                await _handleDeleteSelected();
                              },
                              isMobile: isMobile,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: isMobile ? 12 : 16),
                          ),
                          if (controller.isLoading)
                            const SliverFillRemaining(
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (controller.error != null)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Lỗi: ${controller.error}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            )
                          else if (controller.filteredUsers.isEmpty)
                            SliverFillRemaining(
                              child: Center(
                                child: Text(
                                  'Không tìm thấy tài khoản môi trường',
                                  style: TextStyle(
                                    color: AppColors.adminTextSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final user = controller.filteredUsers[index];
                                final userId = user['id'] as int;
                                return Padding(
                                  padding: EdgeInsets.only(
                                    bottom:
                                        index ==
                                            controller.filteredUsers.length - 1
                                        ? (isMobile ? 16 : 24)
                                        : (isMobile ? 12 : 16),
                                  ),
                                  child: UserCard(
                                    user: user,
                                    isMobile: isMobile,
                                    isTablet: isTablet,
                                    isSelected: controller.isUserSelected(
                                      userId,
                                    ),
                                    onSelectionChanged: (value) {
                                      setState(() {
                                        controller.toggleUserSelection(userId);
                                      });
                                    },
                                    onToggleSelection: () {
                                      setState(() {
                                        controller.toggleUserSelection(userId);
                                      });
                                    },
                                    onEdit: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) =>
                                            EditEnvironmentUserDialog(
                                              user: user,
                                              onUpdated: () {
                                                _loadUsers();
                                              },
                                            ),
                                      );
                                    },
                                    onDelete: () => _handleDeleteUser(user),
                                  ),
                                );
                              }, childCount: controller.filteredUsers.length),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
