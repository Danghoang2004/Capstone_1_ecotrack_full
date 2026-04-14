import 'dart:async';

import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/auth_service.dart';
import 'package:frontend_ecotrack/core/services/environment_task_service.dart';
import 'package:frontend_ecotrack/core/services/notification_service.dart';
import 'package:frontend_ecotrack/core/services/user_service.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/data/models/environment_my_team_info_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_detail_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_navigation_map_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_report_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_overview_tab.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_profile_tab.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/tabs/environment_tasks_tab.dart';
import 'package:frontend_ecotrack/presentation/user_app/notification/notification_screen.dart';

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
  final NotificationService _notificationService = NotificationService();

  List<EnvironmentCleanupTask> _tasks = [];
  bool _isLoading = true;
  int _selectedTab = 0;
  bool _isLoggingOut = false;
  String _username = 'Đội môi trường';
  String _roleLabel = 'ROLE_ENVIRONMENT';
  String _avatarImageUrl = '';
  EnvironmentMyTeamInfo? _myTeamInfo;
  int _unreadNotificationCount = 0;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadMyTeamInfo();
    _loadUnreadNotificationCount();
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
      final unreadCount = await _notificationService.getUnreadCount();
      if (!mounted) return;
      tasks.sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      setState(() {
        _tasks = tasks;
        _unreadNotificationCount = unreadCount;
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

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final unreadCount = await _notificationService.getUnreadCount();
      if (!mounted) return;
      setState(() => _unreadNotificationCount = unreadCount);
    } catch (_) {
      if (!mounted) return;
      setState(() => _unreadNotificationCount = 0);
    }
  }

  Future<void> _openNotificationPage() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const NotificationScreen()));
    await _loadUnreadNotificationCount();
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

  Future<void> _loadMyTeamInfo() async {
    final teamInfo = await _taskService.fetchMyTeamInfo();
    if (!mounted) return;
    setState(() => _myTeamInfo = teamInfo);
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
        myTeamInfo: _myTeamInfo,
        onLogout: _logout,
        isLoggingOut: _isLoggingOut,
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
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
                fontSize: 22,
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
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Thông báo',
                onPressed: _openNotificationPage,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Color(0xFF1F2D1D),
                  size: 24,
                ),
              ),
              if (_unreadNotificationCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 20),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _unreadNotificationCount > 99
                          ? '99+'
                          : '$_unreadNotificationCount',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Tài khoản',
            onPressed: () => setState(() => _selectedTab = 2),
            icon: Container(
              width: 40,
              height: 40,
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
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(index: _selectedTab, children: pages),
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedTab,
          onDestinationSelected: (index) => setState(() => _selectedTab = index),
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF5EAC24).withOpacity(0.16),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          elevation: 0,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey.shade700),
              selectedIcon: const Icon(Icons.home, color: Color(0xFF5EAC24)),
              label: 'Tổng quan',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined, color: Colors.grey.shade700),
              selectedIcon: const Icon(Icons.assignment, color: Color(0xFF5EAC24)),
              label: 'Công việc',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.grey.shade700),
              selectedIcon: const Icon(Icons.person, color: Color(0xFF5EAC24)),
              label: 'Tài khoản',
            ),
          ],
        ),
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
