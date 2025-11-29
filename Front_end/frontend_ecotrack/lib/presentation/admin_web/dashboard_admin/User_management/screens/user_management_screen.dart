import 'package:flutter/material.dart';
import '../controllers/user_management_controller.dart';
import '../widgets/header/user_management_header.dart';
import '../widgets/search/user_search_bar.dart';
import '../widgets/filter/user_filter_bar.dart';
import '../widgets/user_card/user_card.dart';
import '../widgets/edit_user_dialog/edit_user_dialog.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  late final UserManagementController controller = UserManagementController();

  @override
  void initState() {
    super.initState();
    controller.searchController.addListener(_onSearchChanged);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    await controller.loadUsers();
    if (mounted) {
      setState(() {});
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
            'Bạn có chắc chắn muốn xóa $count người dùng đã chọn? Hành động này không thể hoàn tác.',
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
              content: Text('Đã xóa $count người dùng thành công'),
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
            'Bạn có chắc chắn muốn xóa người dùng "${user['name']}"? Hành động này không thể hoàn tác.',
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
              content: Text('Đã xóa người dùng thành công'),
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
  void dispose() {
    controller.searchController.removeListener(_onSearchChanged);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 1300,
              ),
              padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- HEADER ---
                  UserManagementHeader(isMobile: isMobile, isTablet: isTablet),

                  SizedBox(height: isMobile ? 20 : 32),

                  // --- SEARCH BAR (Fixed khi cuộn) ---
                  UserSearchBar(
                    controller: controller.searchController,
                    isMobile: isMobile,
                  ),

                  SizedBox(height: isMobile ? 16 : 24),

                  // --- CONTENT AREA (Scrollable) ---
                  Expanded(
                    child: CustomScrollView(
                      slivers: [
                        // --- FILTER BAR (Sắp xếp + Chọn tất cả) - Không fixed ---
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

                        // --- USER LIST ---
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
                                'Không tìm thấy người dùng',
                                style: TextStyle(
                                  color: Colors.grey[500],
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
                                      ? (isMobile
                                            ? 16
                                            : 24) // Padding bottom cho item cuối
                                      : (isMobile ? 12 : 16),
                                ),
                                child: UserCard(
                                  user: user,
                                  isMobile: isMobile,
                                  isTablet: isTablet,
                                  isSelected: controller.isUserSelected(userId),
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
                                      builder: (context) => EditUserDialog(
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
          );
        },
      ),
    );
  }
}
