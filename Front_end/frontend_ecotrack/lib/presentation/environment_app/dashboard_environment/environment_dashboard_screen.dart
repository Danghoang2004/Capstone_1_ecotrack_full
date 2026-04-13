import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/core/services/environment_task_service.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_detail_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_navigation_map_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_report_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_overview_tab.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_profile_tab.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_tasks_tab.dart';

class EnvironmentDashboardScreen extends StatefulWidget {
  const EnvironmentDashboardScreen({super.key});

  @override
  State<EnvironmentDashboardScreen> createState() =>
      _EnvironmentDashboardScreenState();
}

class _EnvironmentDashboardScreenState
    extends State<EnvironmentDashboardScreen> {
  final AuthService _authService = AuthService();
  final EnvironmentTaskService _taskService = EnvironmentTaskService();
  final UserService _userService = UserService();

  List<EnvironmentCleanupTask> _tasks = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  bool _isLoggingOut = false;
  String _username = 'Đội môi trường';
  String _roleLabel = 'ROLE_ENVIRONMENT';
  String _avatarImageUrl = '';
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadTasks();
    _startRealtimePolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startRealtimePolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => _loadTasks(silent: true),
    );
  }

  Future<void> _loadTasks({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final tasks = await _taskService.fetchMyTasks();
      if (!mounted) return;
      tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_friendlyError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadProfile() async {
    final username = await _authService.getUsername();
    final roles = await _authService.getRoles();

    String avatarImageUrl = '';
    try {
      final profile = await _userService.getProfileView();
      avatarImageUrl = _userService.apiClient.buildImageUrl(profile.avatarUrl);
    } catch (_) {
      avatarImageUrl = '';
    }

    if (!mounted) return;
    setState(() {
      _username = (username == null || username.trim().isEmpty)
          ? 'Đội môi trường'
          : username;
      _roleLabel = roles.isEmpty ? 'ROLE_ENVIRONMENT' : roles.first;
      _avatarImageUrl = avatarImageUrl;
    });
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'E';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    final first = parts.first[0].toUpperCase();
    final last = parts.last.isEmpty ? 'E' : parts.last[0].toUpperCase();
    return '$first$last';
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('phiên') || text.contains('hết hạn')) {
      return 'Phiên đăng nhập không hợp lệ. Vui lòng đăng nhập lại.';
    }
    return text.replaceFirst('Exception: ', '');
  }

  Future<void> _openTaskReportPage(EnvironmentCleanupTask task) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EnvironmentTaskReportScreen(task: task),
      ),
    );

    if (result == true) {
      await _loadTasks();
    }
  }

  Future<void> _openTaskDetailPage(EnvironmentCleanupTask task) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EnvironmentTaskDetailScreen(task: task),
      ),
    );

    if (updated == true) {
      await _loadTasks();
    }
  }

  Future<void> _openTaskNavigationMap(EnvironmentCleanupTask task) async {
    double? destLat = task.reportGpsLat;
    double? destLong = task.reportGpsLong;

    if (destLat == null || destLong == null) {
      final fallback = await _taskService.fetchTaskDestinationByReportId(
        task.reportId,
      );
      if (fallback != null) {
        destLat = fallback.latitude;
        destLong = fallback.longitude;
      }
    }

    if (destLat == null || destLong == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Báo cáo của task này chưa có GPS đích. Vui lòng kiểm tra dữ liệu báo cáo gốc.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EnvironmentTaskNavigationMapScreen(
          taskTitle: task.reportTitle,
          destinationLat: destLat!,
          destinationLong: destLong!,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    if (_isLoggingOut) return;
    setState(() => _isLoggingOut = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      EnvironmentOverviewTab(
        tasks: _tasks,
        isLoading: _isLoading,
        onRefresh: _loadTasks,
        onOpenTaskDetailPage: _openTaskDetailPage,
        onOpenTaskNavigationMap: _openTaskNavigationMap,
        onOpenTaskReportPage: _openTaskReportPage,
      ),
      EnvironmentTasksTab(
        tasks: _tasks,
        isLoading: _isLoading,
        onRefresh: _loadTasks,
        onOpenTaskDetailPage: _openTaskDetailPage,
        onOpenTaskNavigationMap: _openTaskNavigationMap,
        onOpenTaskReportPage: _openTaskReportPage,
      ),
      EnvironmentProfileTab(
        userName: _username,
        userRole: _roleLabel,
        avatarImageUrl: _avatarImageUrl,
        onLogout: _logout,
        isLoggingOut: _isLoggingOut,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Environment App',
              style: TextStyle(
                color: Color(0xFF1F2D1D),
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
            Text(
              'Xin chào $_username',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Tài khoản',
            onPressed: () => setState(() => _selectedTab = 2),
            icon: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD7E7D1), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: _avatarImageUrl.isNotEmpty
                    ? Image.network(
                        _avatarImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _avatarFallback(),
                      )
                    : _avatarFallback(),
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF5EAC24).withOpacity(0.14),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Tổng quan',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Công việc',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _avatarFallback() {
    return Container(
      color: const Color(0xFFEAF5E4),
      alignment: Alignment.center,
      child: Text(
        _initials(_username),
        style: const TextStyle(
          color: Color(0xFF2F6F3E),
          fontWeight: FontWeight.w800,
          fontSize: 13,
        ),
      ),
    );
  }
}
