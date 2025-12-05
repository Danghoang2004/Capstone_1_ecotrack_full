import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';

class UserManagementController {
  final TextEditingController searchController = TextEditingController();
  final UserService _userService = UserService();

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = false;
  String? _error;
  String? _sortOrder; // 'high' hoặc 'low'
  final Set<int> _selectedUserIds = {}; // Set các user ID đã được chọn

  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get sortOrder => _sortOrder;
  Set<int> get selectedUserIds => _selectedUserIds;
  bool get isAllSelected =>
      _filteredUsers.isNotEmpty &&
      _selectedUserIds.length == _filteredUsers.length;
  bool get hasSelectedUsers => _selectedUserIds.isNotEmpty;

  UserManagementController() {
    // loadUsers() sẽ được gọi từ screen để có thể trigger setState
  }

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    try {
      final data = await _userService.getAllUsers();
      _users = data.map((json) {
        // Chuyển đổi từ API response sang format UI cần
        return {
          'id': json['id'],
          'name': json['fullName'] ?? json['username'] ?? '',
          'email': json['email'] ?? '',
          'username': json['username'] ?? '',
          'phone': '', // API chưa có phone
          'points': json['points'] ?? 0,
          'rank': json['rank'] ?? 0,
          'reports': json['reports'] ?? 0,
          'campaigns': json['campaigns'] ?? 0,
          'status': (json['isActive'] == true) ? 'active' : 'inactive',
          'avatarUrl': json['avatarUrl'],
        };
      }).toList();
      _filteredUsers = _users;
    } catch (e) {
      _error = e.toString();
      _users = [];
      _filteredUsers = [];
    } finally {
      _isLoading = false;
    }
  }

  void _filterUsers() {
    final query = searchController.text.toLowerCase();
    List<Map<String, dynamic>> filtered;

    if (query.isEmpty) {
      filtered = List.from(_users);
    } else {
      filtered = _users.where((user) {
        return user['name'].toString().toLowerCase().contains(query) ||
            user['email'].toString().toLowerCase().contains(query);
      }).toList();
    }

    // Áp dụng sắp xếp
    _applySort(filtered);
    _filteredUsers = filtered;
  }

  void _applySort(List<Map<String, dynamic>> list) {
    if (_sortOrder == null) return;

    list.sort((a, b) {
      final pointsA = (a['points'] as int? ?? 0);
      final pointsB = (b['points'] as int? ?? 0);

      if (_sortOrder == 'high') {
        return pointsB.compareTo(pointsA); // Cao → Thấp
      } else if (_sortOrder == 'low') {
        return pointsA.compareTo(pointsB); // Thấp → Cao
      }
      return 0;
    });
  }

  // Public method để screen có thể gọi
  void filterUsers() {
    _filterUsers();
  }

  void setSortOrder(String? order) {
    _sortOrder = order;
    _filterUsers();
  }

  void toggleUserSelection(int userId) {
    if (_selectedUserIds.contains(userId)) {
      _selectedUserIds.remove(userId);
    } else {
      _selectedUserIds.add(userId);
    }
  }

  void selectAll() {
    _selectedUserIds.clear();
    for (var user in _filteredUsers) {
      _selectedUserIds.add(user['id'] as int);
    }
  }

  void deselectAll() {
    _selectedUserIds.clear();
  }

  bool isUserSelected(int userId) {
    return _selectedUserIds.contains(userId);
  }

  Future<void> deleteUser(int userId) async {
    try {
      await _userService.deleteUser(userId);
      // Xóa user khỏi danh sách
      _users.removeWhere((user) => user['id'] == userId);
      _selectedUserIds.remove(userId);
      _filterUsers(); // Refresh filtered list
    } catch (e) {
      _error = e.toString();
      rethrow; // Re-throw để screen có thể hiển thị error
    }
  }

  Future<void> deleteSelectedUsers() async {
    if (_selectedUserIds.isEmpty) return;

    try {
      final userIds = _selectedUserIds.toList();
      await _userService.deleteUsers(userIds);
      // Xóa các user đã chọn khỏi danh sách
      _users.removeWhere((user) => _selectedUserIds.contains(user['id']));
      _selectedUserIds.clear();
      _filterUsers(); // Refresh filtered list
    } catch (e) {
      _error = e.toString();
      rethrow; // Re-throw để screen có thể hiển thị error
    }
  }

  void dispose() {
    searchController.dispose();
  }
}
