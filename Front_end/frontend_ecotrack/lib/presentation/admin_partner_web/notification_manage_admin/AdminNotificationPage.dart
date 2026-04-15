import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/data/models/NotificationModelAdmin.dart';
import 'create_notification_screen.dart';
import 'package:intl/intl.dart';

class AdminNotificationPage extends StatefulWidget {
  const AdminNotificationPage({super.key});

  @override
  State<AdminNotificationPage> createState() => _AdminNotificationPageState();
}

class _AdminNotificationPageState extends State<AdminNotificationPage> {
  final NotificationService _notificationService = NotificationService();
  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _filteredNotifications = [];
  bool _isLoading = true;
  bool _isMutating = false;
  
  // Filter & Search
  String _searchQuery = '';
  String _filterStatus = 'all'; // all, read, unread
  String _sortBy = 'newest'; // newest, oldest, title
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  
  // Bulk selection
  final Set<int> _selectedIds = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await _notificationService.getAdminNotifications();
      setState(() {
        _allNotifications = data;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print("Lỗi lấy danh sách Admin: $e");
      setState(() => _isLoading = false);
    }
  }

  void _applyFilters() {
    var filtered = List<NotificationModel>.from(_allNotifications);
    
    // Search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((n) =>
              n.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              n.message.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    // Status filter
    if (_filterStatus == 'read') {
      filtered = filtered.where((n) => n.isRead).toList();
    } else if (_filterStatus == 'unread') {
      filtered = filtered.where((n) => !n.isRead).toList();
    }
    
    // Sorting
    if (_sortBy == 'newest') {
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    } else if (_sortBy == 'oldest') {
      filtered.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    } else if (_sortBy == 'title') {
      filtered.sort((a, b) => a.title.compareTo(b.title));
    }
    
    setState(() {
      _filteredNotifications = filtered;
      _currentPage = 1;
      _selectAll = false;
      _selectedIds.clear();
    });
  }

  List<NotificationModel> _getPaginatedList() {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = start + _itemsPerPage;
    return _filteredNotifications.sublist(
      start,
      end > _filteredNotifications.length ? _filteredNotifications.length : end,
    );
  }

  int get _totalPages =>
      (_filteredNotifications.length / _itemsPerPage).ceil();

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedIds.addAll(_getPaginatedList().map((n) => n.id));
      } else {
        _selectedIds.clear();
      }
    });
  }

  void _toggleNotificationSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _selectAll = false;
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _showEditDialog(NotificationModel item) async {
    final titleController = TextEditingController(text: item.title);
    final messageController = TextEditingController(text: item.message);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Chỉnh sửa thông báo'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tiêu đề'),
                const SizedBox(height: 8),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập tiêu đề',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Nội dung'),
                const SizedBox(height: 8),
                TextField(
                  controller: messageController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Nhập nội dung thông báo',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Lưu thay đổi'),
            ),
          ],
        );
      },
    );

    if (result != true) {
      titleController.dispose();
      messageController.dispose();
      return;
    }

    final title = titleController.text.trim();
    final message = messageController.text.trim();
    titleController.dispose();
    messageController.dispose();

    if (title.isEmpty || message.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tiêu đề và nội dung không được để trống.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isMutating = true);
    final success = await _notificationService.updateAdminNotification(
      id: item.id,
      title: title,
      message: message,
    );
    if (mounted) {
      setState(() => _isMutating = false);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã cập nhật thông báo.'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật thông báo. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNotification(NotificationModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa thông báo'),
          content: Text(
            'Bạn có chắc muốn xóa thông báo "${item.title}"? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isMutating = true);
    final success = await _notificationService.deleteAdminNotification(item.id);
    if (mounted) {
      setState(() => _isMutating = false);
    }

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã xóa thông báo.'),
          backgroundColor: Colors.green,
        ),
      );
      await _fetchNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể xóa thông báo. Vui lòng thử lại.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _bulkDelete() async {
    if (_selectedIds.isEmpty) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa hàng loạt'),
          content: Text(
            'Bạn muốn xóa ${_selectedIds.length} thông báo? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa tất cả', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _isMutating = true);
    int successCount = 0;
    int failCount = 0;

    for (int id in _selectedIds) {
      final success = await _notificationService.deleteAdminNotification(id);
      if (success) {
        successCount++;
      } else {
        failCount++;
      }
    }

    if (mounted) {
      setState(() => _isMutating = false);
    }

    if (!mounted) return;
    
    String message = failCount == 0
        ? 'Đã xóa $successCount thông báo.'
        : 'Xóa $successCount thông báo thành công, $failCount thất bại.';
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
      ),
    );
    
    await _fetchNotifications();
  }

  @override
  Widget build(BuildContext context) {
    final paginatedList = _getPaginatedList();
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quản Lý Thông Báo",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  if (_selectedIds.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        label: Text(
                          'Xóa ${_selectedIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: _isMutating ? null : _bulkDelete,
                      ),
                    ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text(
                      "Tạo thông báo mới",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5EAC24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onPressed: _isMutating
                        ? null
                        : () async {
                            await showDialog<void>(
                              context: context,
                              barrierDismissible: false,
                              builder: (dialogContext) =>
                                  const CreateNotificationScreen(),
                            );
                            _fetchNotifications();
                          },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                // Search
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        onChanged: (value) {
                          setState(() => _searchQuery = value);
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm tiêu đề hoặc nội dung...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Filter Status
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterStatus,
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('Tất cả')),
                          DropdownMenuItem(
                            value: 'read',
                            child: Text('Đã đọc'),
                          ),
                          DropdownMenuItem(
                            value: 'unread',
                            child: Text('Chưa đọc'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() => _filterStatus = value ?? 'all');
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: 'Lọc theo trạng thái',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Sort By
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                          DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                          DropdownMenuItem(value: 'title', child: Text('Tiêu đề A-Z')),
                        ],
                        onChanged: (value) {
                          setState(() => _sortBy = value ?? 'newest');
                          _applyFilters();
                        },
                        decoration: InputDecoration(
                          labelText: 'Sắp xếp theo',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Items count
          Text(
            'Tìm thấy ${_filteredNotifications.length} thông báo',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),

          // List or Empty State
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredNotifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none,
                                size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Chưa có thông báo nào',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: paginatedList.length,
                        itemBuilder: (context, index) {
                          final item = paginatedList[index];
                          final isSelected = _selectedIds.contains(item.id);
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: Checkbox(
                                value: isSelected,
                                onChanged: (value) =>
                                    _toggleNotificationSelection(item.id),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  if (!item.isRead)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'Mới',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Text(
                                item.message,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 10,
                              ),
                              isThreeLine: true,
                              titleAlignment: ListTileTitleAlignment.top,
                              dense: false,
                              minVerticalPadding: 8,
                              trailing: SizedBox(
                                width: 180,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          DateFormat('dd/MM/yyyy')
                                              .format(item.createdAt),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('HH:mm')
                                              .format(item.createdAt),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(width: 8),
                                    PopupMenuButton<String>(
                                      enabled: !_isMutating,
                                      onSelected: (value) async {
                                        if (value == 'edit') {
                                          await _showEditDialog(item);
                                        }
                                        if (value == 'delete') {
                                          await _deleteNotification(item);
                                        }
                                      },
                                      itemBuilder: (context) => const [
                                        PopupMenuItem<String>(
                                          value: 'edit',
                                          child: Row(
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 18),
                                              SizedBox(width: 8),
                                              Text('Chỉnh sửa'),
                                            ],
                                          ),
                                        ),
                                        PopupMenuItem<String>(
                                          value: 'delete',
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.red,
                                              ),
                                              SizedBox(width: 8),
                                              Text('Xóa'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Pagination Footer
          if (_filteredNotifications.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Select all checkbox
                  Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: _toggleSelectAll,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Chọn tất cả trang này (${paginatedList.length})',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  // Pagination controls
                  Row(
                    children: [
                      Text(
                        'Trang $_currentPage / $_totalPages',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _currentPage > 1 && !_isMutating
                            ? () =>
                                setState(() => _currentPage--) 
                            : null,
                        child: const Text('← Trước'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _currentPage < _totalPages && !_isMutating
                            ? () =>
                                setState(() => _currentPage++)
                            : null,
                        child: const Text('Sau →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
