import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:frontend_ecotrack/core/services/admin_environment_team_service.dart';
import 'package:frontend_ecotrack/data/models/admin_environment_team_models.dart';
import 'package:frontend_ecotrack/presentation/admin_partner_web/dashboard_admin/AdminEnvironmentTeamTaskDetailsPage.dart';

class AdminEnvironmentTeamPage extends StatefulWidget {
  const AdminEnvironmentTeamPage({super.key});

  @override
  State<AdminEnvironmentTeamPage> createState() =>
      _AdminEnvironmentTeamPageState();
}

class _AdminEnvironmentTeamPageState extends State<AdminEnvironmentTeamPage>
    with SingleTickerProviderStateMixin {
  final AdminEnvironmentTeamService _service = AdminEnvironmentTeamService();
  final _teamNameController = TextEditingController();
  final _teamDescriptionController = TextEditingController();

  late TabController _tabController;
  List<EnvironmentTeam> _teams = [];
  List<EnvironmentTeamKpi> _kpis = [];
  List<EnvironmentTeamUserOption> _users = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isRefreshing = false;
  Timer? _refreshTimer;
  DateTime? _lastSyncedAt;
  String? _error;
  int? _selectedTaskTeamId;
  String? _selectedTaskTeamName;
  String? _selectedTaskFromAt;
  String? _selectedTaskToAt;
  DateTimeRange _kpiRange = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 30)),
    end: DateTime.now(),
  );

  static const Duration _refreshInterval = Duration(seconds: 50);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboard();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _teamNameController.dispose();
    _teamDescriptionController.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadDashboard(silent: true);
    });
  }

  Future<void> _loadDashboard({bool silent = false}) async {
    if (!mounted || _isRefreshing) return;
    if (!silent && mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    setState(() => _isRefreshing = true);

    try {
      final fromAt = DateFormat(
        "yyyy-MM-dd'T'00:00:00",
      ).format(_kpiRange.start);
      final toAt = DateFormat("yyyy-MM-dd'T'23:59:59").format(_kpiRange.end);

      final results = await Future.wait([
        _service.fetchTeams(),
        _service.fetchKpis(fromAt: fromAt, toAt: toAt),
        _service.fetchUsers(),
      ]);

      if (!mounted) return;
      setState(() {
        _teams = results[0] as List<EnvironmentTeam>;
        _kpis = results[1] as List<EnvironmentTeamKpi>;
        _users = _filterEnvironmentUsers(
          results[2] as List<EnvironmentTeamUserOption>,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<EnvironmentTeamUserOption> _filterEnvironmentUsers(
    List<EnvironmentTeamUserOption> users,
  ) {
    return users.where((user) {
      final text = '${user.fullName} ${user.username} ${user.email}'
          .toLowerCase();
      return text.isNotEmpty;
    }).toList();
  }

  int get _totalMembers => _teams.fold<int>(0, (sum, team) {
    final leadCount = team.lead == null ? 0 : 1;
    return sum + leadCount + team.members.length;
  });

  int get _activeTeams => _teams.where((team) => team.isActive).length;

  double get _averageCompletionRate {
    if (_kpis.isEmpty) return 0;
    return _kpis.map((item) => item.completionRate).reduce((a, b) => a + b) /
        _kpis.length;
  }

  Future<void> _createTeam() async {
    final lead = _users.isEmpty ? null : _users.first;

    final formKey = GlobalKey<FormState>();
    int? selectedLeadId = lead?.userId;

    final created = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo đội môi trường mới'),
              content: SizedBox(
                width: 560,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _teamNameController,
                        decoration: const InputDecoration(
                          labelText: 'Tên đội',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập tên đội';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _teamDescriptionController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Mô tả đội',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: selectedLeadId,
                        decoration: const InputDecoration(
                          labelText: 'Team lead',
                          border: OutlineInputBorder(),
                        ),
                        items: _users
                            .map(
                              (user) => DropdownMenuItem<int>(
                                value: user.userId,
                                child: Text(user.displayLabel),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => setDialogState(() {
                          selectedLeadId = value;
                        }),
                        validator: (value) {
                          if (value == null) return 'Chọn một lead';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Thành viên bổ sung có thể thêm sau khi tạo đội.',
                          style: TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Huỷ'),
                ),
                ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () {
                          if (formKey.currentState?.validate() != true) return;
                          Navigator.of(context).pop(true);
                        },
                  child: const Text('Tạo đội'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created != true || selectedLeadId == null) return;

    await _runAction(() async {
      await _service.createTeam(
        teamName: _teamNameController.text.trim(),
        description: _teamDescriptionController.text.trim(),
        leadUserId: selectedLeadId!,
      );
      _teamNameController.clear();
      _teamDescriptionController.clear();
      await _loadDashboard(silent: true);
    }, successMessage: 'Đã tạo đội mới.');
  }

  Future<void> _editTeam(EnvironmentTeam team) async {
    final nameController = TextEditingController(text: team.teamName);
    final descriptionController = TextEditingController(text: team.description);
    bool isActive = team.isActive;

    final updated = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Chỉnh sửa ${team.teamName}'),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên đội',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile.adaptive(
                      value: isActive,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (value) =>
                          setDialogState(() => isActive = value),
                      title: const Text('Kích hoạt đội'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Huỷ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
      },
    );

    if (updated != true) return;

    await _runAction(() async {
      await _service.updateTeam(
        teamId: team.teamId,
        teamName: nameController.text.trim(),
        description: descriptionController.text.trim(),
        isActive: isActive,
      );
      await _loadDashboard(silent: true);
    }, successMessage: 'Đã cập nhật đội.');
  }

  Future<void> _changeLead(EnvironmentTeam team) async {
    final candidates = <EnvironmentTeamUserOption>{
      if (team.lead != null) ...[
        EnvironmentTeamUserOption(
          userId: team.lead!.userId,
          fullName: team.lead!.fullName,
          username: team.lead!.username,
          email: team.lead!.email,
        ),
      ],
      ...team.members.map(
        (member) => EnvironmentTeamUserOption(
          userId: member.userId,
          fullName: member.fullName,
          username: member.username,
          email: member.email,
        ),
      ),
    }.toList();

    if (candidates.isEmpty) {
      await _showSnack(
        'Đội này chưa có thành viên để chuyển lead.',
        isError: true,
      );
      return;
    }

    int? selectedUserId = team.lead?.userId ?? candidates.first.userId;
    final changed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Đổi lead của ${team.teamName}'),
          content: DropdownButtonFormField<int>(
            value: selectedUserId,
            decoration: const InputDecoration(
              labelText: 'Chọn lead mới',
              border: OutlineInputBorder(),
            ),
            items: candidates
                .map(
                  (user) => DropdownMenuItem<int>(
                    value: user.userId,
                    child: Text(user.displayLabel),
                  ),
                )
                .toList(),
            onChanged: (value) => selectedUserId = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Cập nhật'),
            ),
          ],
        );
      },
    );

    if (changed != true || selectedUserId == null) return;

    await _runAction(() async {
      await _service.setTeamLead(teamId: team.teamId, userId: selectedUserId!);
      await _loadDashboard(silent: true);
    }, successMessage: 'Đã đổi lead.');
  }

  Future<void> _addMember(EnvironmentTeam team) async {
    final existingIds = {
      if (team.lead != null) team.lead!.userId,
      ...team.members.map((member) => member.userId),
    };

    final candidates = _users
        .where((user) => !existingIds.contains(user.userId))
        .toList();
    if (candidates.isEmpty) {
      await _showSnack(
        'Không thể thêm member vì hiện không còn tài khoản ROLE_ENVIRONMENT khả dụng. Hãy tạo/gán thêm tài khoản môi trường trước.',
        isError: true,
      );
      return;
    }

    int? selectedUserId = candidates.first.userId;
    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Thêm thành viên cho ${team.teamName}'),
          content: DropdownButtonFormField<int>(
            value: selectedUserId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Người dùng',
              border: OutlineInputBorder(),
            ),
            items: candidates
                .map(
                  (user) => DropdownMenuItem<int>(
                    value: user.userId,
                    child: Text(user.displayLabel),
                  ),
                )
                .toList(),
            onChanged: (value) => selectedUserId = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );

    if (added != true || selectedUserId == null) return;

    await _runAction(() async {
      await _service.addMember(teamId: team.teamId, userId: selectedUserId!);
      await _loadDashboard(silent: true);
    }, successMessage: 'Đã thêm thành viên.');
  }

  Future<void> _removeMember(
    EnvironmentTeam team,
    EnvironmentTeamMember member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoá thành viên'),
          content: Text('Xoá ${member.fullName} khỏi ${team.teamName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huỷ'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text('Xoá'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _runAction(() async {
      await _service.removeMember(teamId: team.teamId, userId: member.userId);
      await _loadDashboard(silent: true);
    }, successMessage: 'Đã xoá thành viên.');
  }

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await action();
      if (!mounted) return;
      await _showSnack(successMessage);
    } catch (e) {
      if (!mounted) return;
      await _showSnack(
        e.toString().replaceFirst('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _showSnack(String message, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF2563EB),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF1F2D1D),
                unselectedLabelColor: const Color(0xFF6B7280),
                indicatorColor: const Color(0xFF5EAC24),
                tabs: const [
                  Tab(text: 'Tổng quan'),
                  Tab(text: 'Đội nhóm'),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? _buildErrorState()
                    : TabBarView(
                        controller: _tabController,
                        children: [_buildOverviewTab(), _buildTeamsTab()],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Quản lý đội môi trường',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D1D),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Thiết kế cho vận hành thực tế: team lead, thành viên, KPI và trạng thái đội được quản lý tập trung.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _isSubmitting ? null : _createTeam,
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Tạo đội mới'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5EAC24),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: () => _loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _MetricCard(
                title: 'Tổng đội',
                value: _teams.length.toString(),
                icon: Icons.groups_outlined,
                color: const Color(0xFF0F766E),
              ),
              _MetricCard(
                title: 'Đội đang hoạt động',
                value: _activeTeams.toString(),
                icon: Icons.verified_outlined,
                color: const Color(0xFF2563EB),
              ),
              _MetricCard(
                title: 'Tổng nhân sự',
                value: _totalMembers.toString(),
                icon: Icons.badge_outlined,
                color: const Color(0xFF7C3AED),
              ),
              _MetricCard(
                title: 'Tỷ lệ hoàn tất trung bình',
                value: '${_averageCompletionRate.toStringAsFixed(1)}%',
                icon: Icons.trending_up_rounded,
                color: const Color(0xFF16A34A),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 1000) {
                return Column(
                  children: [
                    _buildKpiPanel(),
                    const SizedBox(height: 16),
                    _buildTopTeamsPanel(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildKpiPanel()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTopTeamsPanel()),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKpiPanel() {
    final bestTeam = _kpis.isEmpty
        ? null
        : _kpis.reduce((a, b) => a.completionRate > b.completionRate ? a : b);

    return _PanelCard(
      title: 'KPI gần nhất',
      subtitle: 'Tổng hợp theo team lead trong khoảng thời gian đã chọn',
      trailing: TextButton.icon(
        onPressed: _pickKpiRange,
        icon: const Icon(Icons.date_range),
        label: const Text('Đổi khoảng thời gian'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SmallStat(
                label: 'Assigned',
                value: _sumKpi((item) => item.totalAssigned).toString(),
              ),
              _SmallStat(
                label: 'Pending',
                value: _sumKpi((item) => item.totalCompletedPending).toString(),
              ),
              _SmallStat(
                label: 'Resolved',
                value: _sumKpi((item) => item.totalResolved).toString(),
              ),
              _SmallStat(
                label: 'Tỷ lệ TB',
                value: '${_averageCompletionRate.toStringAsFixed(1)}%',
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (bestTeam != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xFFEAF5E4), Color(0xFFF7FBF5)],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5EAC24).withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_outlined,
                      color: Color(0xFF2F6F3E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Đội đang dẫn đầu',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bestTeam.teamName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${bestTeam.completionRate.toStringAsFixed(1)}% hoàn tất, trung bình ${bestTeam.avgResolutionMinutes ?? 0} phút',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'Bảng KPI chi tiết',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          _buildKpiTable(),
        ],
      ),
    );
  }

  Widget _buildTopTeamsPanel() {
    final ordered = [..._teams];
    ordered.sort((a, b) => a.teamName.compareTo(b.teamName));

    return _PanelCard(
      title: 'Đội hiện tại',
      subtitle: 'Xem nhanh lead, thành viên và trạng thái đội',
      child: ordered.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('Chưa có đội nào được tạo.'),
            )
          : Column(
              children: ordered
                  .take(4)
                  .map(
                    (team) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TeamPreviewCard(
                        team: team,
                        onEdit: () => _editTeam(team),
                        onChangeLead: () => _changeLead(team),
                        onAddMember: () => _addMember(team),
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }

  Widget _buildTeamsTab() {
    if (_selectedTaskTeamId != null && _selectedTaskTeamName != null) {
      final hasRange = _selectedTaskFromAt != null && _selectedTaskToAt != null;
      final subtitle = hasRange
          ? 'Khoảng KPI: ${_formatIsoRange(_selectedTaskFromAt!, _selectedTaskToAt!)}'
          : 'Toàn bộ công việc của đội';

      return RefreshIndicator(
        onRefresh: () => _loadDashboard(),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _PanelCard(
              title: 'Chi tiết công việc: $_selectedTaskTeamName',
              subtitle: subtitle,
              trailing: TextButton.icon(
                onPressed: _closeTeamTaskDetailsInFrame,
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Quay lại danh sách đội'),
              ),
              child: AdminEnvironmentTeamTaskDetailsPanel(
                teamId: _selectedTaskTeamId!,
                teamName: _selectedTaskTeamName!,
                fromAt: _selectedTaskFromAt,
                toAt: _selectedTaskToAt,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadDashboard(),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          _PanelCard(
            title: 'Danh sách đội',
            subtitle:
                'Cấu trúc theo team lead và thành viên, thao tác nhanh ngay trên card',
            child: _teams.isEmpty
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Text('Chưa có đội nào.'),
                  )
                : Column(
                    children: _teams
                        .map(
                          (team) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _TeamDetailCard(
                              team: team,
                              onViewTasks: () => _openTeamTaskDetails(team),
                              onEdit: () => _editTeam(team),
                              onChangeLead: () => _changeLead(team),
                              onAddMember: () => _addMember(team),
                              onRemoveMember: (member) =>
                                  _removeMember(team, member),
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiTable() {
    if (_kpis.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Text('Chưa có dữ liệu KPI trong khoảng thời gian đã chọn.'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        columns: const [
          DataColumn(label: Text('Đội')),
          DataColumn(label: Text('Assigned')),
          DataColumn(label: Text('Pending')),
          DataColumn(label: Text('Resolved')),
          DataColumn(label: Text('Tỷ lệ')),
          DataColumn(label: Text('TB phút')),
        ],
        rows: _kpis
            .map(
              (item) => DataRow(
                onSelectChanged: (_) => _openKpiTaskDetails(item),
                cells: [
                  DataCell(Text(item.teamName)),
                  DataCell(Text(item.totalAssigned.toString())),
                  DataCell(Text(item.totalCompletedPending.toString())),
                  DataCell(Text(item.totalResolved.toString())),
                  DataCell(Text('${item.completionRate.toStringAsFixed(1)}%')),
                  DataCell(Text(item.avgResolutionMinutes?.toString() ?? '-')),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Future<void> _openKpiTaskDetails(EnvironmentTeamKpi kpi) async {
    final fromAt = DateFormat("yyyy-MM-dd'T'00:00:00").format(_kpiRange.start);
    final toAt = DateFormat("yyyy-MM-dd'T'23:59:59").format(_kpiRange.end);

    if (!mounted) return;
    setState(() {
      _selectedTaskTeamId = kpi.teamId;
      _selectedTaskTeamName = kpi.teamName;
      _selectedTaskFromAt = fromAt;
      _selectedTaskToAt = toAt;
    });
    _tabController.animateTo(1);
  }

  Future<void> _openTeamTaskDetails(EnvironmentTeam team) async {
    if (!mounted) return;
    setState(() {
      _selectedTaskTeamId = team.teamId;
      _selectedTaskTeamName = team.teamName;
      _selectedTaskFromAt = null;
      _selectedTaskToAt = null;
    });
  }

  void _closeTeamTaskDetailsInFrame() {
    setState(() {
      _selectedTaskTeamId = null;
      _selectedTaskTeamName = null;
      _selectedTaskFromAt = null;
      _selectedTaskToAt = null;
    });
  }

  String _formatIsoRange(String fromAt, String toAt) {
    final from = DateTime.tryParse(fromAt);
    final to = DateTime.tryParse(toAt);
    if (from == null || to == null) {
      return '$fromAt - $toAt';
    }
    return '${DateFormat('dd/MM/yyyy').format(from)} - ${DateFormat('dd/MM/yyyy').format(to)}';
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
          const SizedBox(height: 12),
          Text(_error ?? 'Có lỗi xảy ra'),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _loadDashboard,
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  int _sumKpi(int Function(EnvironmentTeamKpi item) selector) {
    return _kpis.fold<int>(0, (sum, item) => sum + selector(item));
  }

  Future<void> _pickKpiRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _kpiRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5EAC24),
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    setState(() => _kpiRange = picked);
    await _loadDashboard();
  }
}

class _PanelCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  const _PanelCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2D1D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EDE2)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  final String label;
  final String value;

  const _SmallStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE6EDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _TeamPreviewCard extends StatelessWidget {
  final EnvironmentTeam team;
  final VoidCallback onEdit;
  final VoidCallback onChangeLead;
  final VoidCallback onAddMember;

  const _TeamPreviewCard({
    required this.team,
    required this.onEdit,
    required this.onChangeLead,
    required this.onAddMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECDf)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.teamName,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      team.description.isEmpty
                          ? 'Chưa có mô tả'
                          : team.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: team.isActive
                      ? const Color(0xFFE7F7EA)
                      : const Color(0xFFFDECEC),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  team.isActive ? 'Đang hoạt động' : 'Tạm dừng',
                  style: TextStyle(
                    color: team.isActive
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (team.lead != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(
                    Icons.emoji_events_outlined,
                    size: 18,
                    color: Color(0xFF2F6F3E),
                  ),
                  label: Text('Lead: ${team.lead!.fullName}'),
                ),
                Chip(label: Text('Member: ${team.members.length}')),
              ],
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Sửa'),
              ),
              OutlinedButton.icon(
                onPressed: onChangeLead,
                icon: const Icon(Icons.swap_horiz),
                label: const Text('Đổi lead'),
              ),
              OutlinedButton.icon(
                onPressed: onAddMember,
                icon: const Icon(Icons.person_add_alt_1),
                label: const Text('Thêm member'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TeamDetailCard extends StatelessWidget {
  final EnvironmentTeam team;
  final VoidCallback onViewTasks;
  final VoidCallback onEdit;
  final VoidCallback onChangeLead;
  final VoidCallback onAddMember;
  final Future<void> Function(EnvironmentTeamMember member) onRemoveMember;

  const _TeamDetailCard({
    required this.team,
    required this.onViewTasks,
    required this.onEdit,
    required this.onChangeLead,
    required this.onAddMember,
    required this.onRemoveMember,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE6EDE2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          team.teamName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _statusChip(team.isActive),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      team.description.isEmpty
                          ? 'Chưa có mô tả cho đội này.'
                          : team.description,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _personChip('Lead', team.lead),
                        _StatBubble(
                          label: 'Members',
                          value: team.members.length.toString(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onViewTasks,
                    icon: const Icon(Icons.assignment_outlined),
                    label: const Text('Xem công việc'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Sửa'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChangeLead,
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text('Đổi lead'),
                  ),
                  FilledButton.icon(
                    onPressed: onAddMember,
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Thêm member'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (team.members.isEmpty)
            const Text('Chưa có thành viên nào.')
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: team.members
                  .map(
                    (member) => InputChip(
                      avatar: CircleAvatar(
                        backgroundColor: const Color(0xFFEAF5E4),
                        child: Text(
                          member.fullName.isNotEmpty
                              ? member.fullName[0].toUpperCase()
                              : 'M',
                          style: const TextStyle(color: Color(0xFF2F6F3E)),
                        ),
                      ),
                      label: Text(member.fullName),
                      onDeleted: () => onRemoveMember(member),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
    );
  }

  Widget _statusChip(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F7EE) : const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _personChip(String label, EnvironmentTeamMember? person) {
    if (person == null) return const SizedBox.shrink();
    return Chip(label: Text('$label: ${person.fullName}'));
  }
}

class _StatBubble extends StatelessWidget {
  final String label;
  final String value;

  const _StatBubble({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE6EDE2)),
      ),
      child: Text('$label: $value'),
    );
  }
}
