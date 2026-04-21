import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/admin_environment_team_service.dart';
import 'package:frontend_ecotrack/data/models/admin_environment_team_models.dart';
import 'package:intl/intl.dart';

class AdminEnvironmentTeamTaskDetailsPage extends StatefulWidget {
  const AdminEnvironmentTeamTaskDetailsPage({
    super.key,
    required this.teamId,
    required this.teamName,
    this.fromAt,
    this.toAt,
  });

  final int teamId;
  final String teamName;
  final String? fromAt;
  final String? toAt;

  @override
  State<AdminEnvironmentTeamTaskDetailsPage> createState() =>
      _AdminEnvironmentTeamTaskDetailsPageState();
}

class _AdminEnvironmentTeamTaskDetailsPageState
    extends State<AdminEnvironmentTeamTaskDetailsPage> {
  String _formatIsoRange(String fromAt, String toAt) {
    final from = DateTime.tryParse(fromAt);
    final to = DateTime.tryParse(toAt);
    if (from == null || to == null) {
      return '$fromAt - $toAt';
    }
    return '${DateFormat('dd/MM/yyyy').format(from)} - ${DateFormat('dd/MM/yyyy').format(to)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chi tiết công việc: ${widget.teamName}',
              style: const TextStyle(
                color: Color(0xFF1F2D1D),
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (widget.fromAt != null && widget.toAt != null)
              Text(
                'Khoảng KPI: ${_formatIsoRange(widget.fromAt!, widget.toAt!)}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        iconTheme: const IconThemeData(color: Color(0xFF1F2D1D)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AdminEnvironmentTeamTaskDetailsPanel(
              teamId: widget.teamId,
              teamName: widget.teamName,
              fromAt: widget.fromAt,
              toAt: widget.toAt,
            ),
          ],
        ),
      ),
    );
  }
}

class AdminEnvironmentTeamTaskDetailsPanel extends StatefulWidget {
  const AdminEnvironmentTeamTaskDetailsPanel({
    super.key,
    required this.teamId,
    required this.teamName,
    this.fromAt,
    this.toAt,
  });

  final int teamId;
  final String teamName;
  final String? fromAt;
  final String? toAt;

  @override
  State<AdminEnvironmentTeamTaskDetailsPanel> createState() =>
      _AdminEnvironmentTeamTaskDetailsPanelState();
}

class _AdminEnvironmentTeamTaskDetailsPanelState
    extends State<AdminEnvironmentTeamTaskDetailsPanel> {
  final AdminEnvironmentTeamService _service = AdminEnvironmentTeamService();

  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'ALL';
  List<EnvironmentTeamKpiTaskDetail> _allTasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(
    covariant AdminEnvironmentTeamTaskDetailsPanel oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.teamId != widget.teamId ||
        oldWidget.fromAt != widget.fromAt ||
        oldWidget.toAt != widget.toAt) {
      _selectedFilter = 'ALL';
      _loadTasks();
    }
  }

  Future<void> _loadTasks() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final details = await _service.fetchKpiTaskDetails(
        teamId: widget.teamId,
        fromAt: widget.fromAt,
        toAt: widget.toAt,
      );

      if (!mounted) return;
      setState(() {
        _allTasks = details;
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

  List<EnvironmentTeamKpiTaskDetail> get _filteredTasks {
    return _allTasks.where((detail) {
      if (_selectedFilter == 'ALL') return true;
      return detail.taskStatus.toUpperCase() == _selectedFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks;
    final assignedCount = _allTasks
        .where((task) => task.taskStatus.toUpperCase() == 'ASSIGNED')
        .length;
    final pendingCount = _allTasks
        .where(
          (task) => task.taskStatus.toUpperCase() == 'CLEANED_PENDING_CONFIRM',
        )
        .length;
    final resolvedCount = _allTasks
        .where((task) => task.taskStatus.toUpperCase() == 'RESOLVED')
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _summaryCard(
              'Tổng công việc',
              _allTasks.length.toString(),
              const Color(0xFF2563EB),
            ),
            _summaryCard(
              'Chưa làm',
              assignedCount.toString(),
              const Color(0xFF0EA5E9),
            ),
            _summaryCard(
              'Chờ duyệt',
              pendingCount.toString(),
              const Color(0xFFF59E0B),
            ),
            _summaryCard(
              'Đã làm',
              resolvedCount.toString(),
              const Color(0xFF16A34A),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE6EDE2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Lọc theo trạng thái',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1F2D1D),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip('Tất cả', 'ALL'),
                  _filterChip('Chưa làm', 'ASSIGNED'),
                  _filterChip('Chờ duyệt', 'CLEANED_PENDING_CONFIRM'),
                  _filterChip('Đã làm', 'RESOLVED'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                'Hiển thị ${filteredTasks.length}/${_allTasks.length} công việc',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _errorView(_error!)
        else if (filteredTasks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 42),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE6EDE2)),
            ),
            child: const Center(
              child: Text('Không có công việc phù hợp bộ lọc.'),
            ),
          )
        else
          _taskTable(filteredTasks),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
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
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskTable(List<EnvironmentTeamKpiTaskDetail> tasks) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDE2)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactMode = constraints.maxWidth < 980;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: compactMode ? 900 : constraints.maxWidth,
              ),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(
                  const Color(0xFFF1F5F9),
                ),
                dataRowMinHeight: 54,
                dataRowMaxHeight: 70,
                columnSpacing: 18,
                horizontalMargin: 12,
                columns: const [
                  DataColumn(label: Text('Task ID')),
                  DataColumn(label: Text('Báo cáo')),
                  DataColumn(label: Text('Lead xử lý')),
                  DataColumn(label: Text('Trạng thái task')),
                  DataColumn(label: Text('Trạng thái report')),
                  DataColumn(label: Text('Giao lúc')),
                ],
                rows: tasks
                    .map(
                      (detail) => DataRow(
                        cells: [
                          DataCell(Text('#${detail.taskId}')),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                detail.reportTitle.isEmpty
                                    ? 'Báo cáo #${detail.reportId}'
                                    : detail.reportTitle,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 150),
                              child: Text(
                                detail.assigneeLeadName,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          DataCell(_taskStatusBadge(detail.taskStatus)),
                          DataCell(Text(detail.reportStatus ?? '-')),
                          DataCell(Text(_formatDateTime(detail.assignedAt))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _taskStatusBadge(String status) {
    final normalized = status.toUpperCase();
    Color color;
    String label;
    switch (normalized) {
      case 'ASSIGNED':
        color = const Color(0xFF2563EB);
        label = 'Chưa làm';
        break;
      case 'CLEANED_PENDING_CONFIRM':
        color = const Color(0xFFF59E0B);
        label = 'Chờ duyệt';
        break;
      case 'RESOLVED':
        color = const Color(0xFF16A34A);
        label = 'Đã làm';
        break;
      default:
        color = const Color(0xFF64748B);
        label = normalized;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final selected = _selectedFilter == value;
    const selectedColor = Color(0xFF2563EB);
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() => _selectedFilter = value);
      },
      selectedColor: selectedColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? selectedColor : const Color(0xFF334155),
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected ? selectedColor : const Color(0xFFE2E8F0),
      ),
      backgroundColor: Colors.white,
    );
  }

  Widget _errorView(String errorText) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 38),
          const SizedBox(height: 10),
          Text(
            errorText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          ElevatedButton(onPressed: _loadTasks, child: const Text('Thử lại')),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return '-';
    return DateFormat('dd/MM/yyyy HH:mm').format(value);
  }
}
