import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/core/services/admin_environment_task_service.dart';
import 'package:frontend_ecotrack/core/theme/app_colors.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/data/models/environment_team_lead_model.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:intl/intl.dart';

class AdminEnvironmentTaskPage extends StatefulWidget {
  const AdminEnvironmentTaskPage({super.key});

  @override
  State<AdminEnvironmentTaskPage> createState() => _AdminEnvironmentTaskPageState();
}

class _AdminEnvironmentTaskPageState extends State<AdminEnvironmentTaskPage> {
  final AdminEnvironmentTaskService _service = AdminEnvironmentTaskService();
  final ReportServiceAdmin _reportService = ReportServiceAdmin();
  final TextEditingController _noteCtrl = TextEditingController();

  List<EnvironmentCleanupTask> _tasks = [];
  List<Report> _assignableReports = [];
  List<EnvironmentTeamLead> _teamLeads = [];

  int? _selectedReportId;
  int? _selectedTeamLeadId;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;

  DateTime? _filterStartDate;
  TimeOfDay? _filterStartTime;
  DateTime? _filterEndDate;
  TimeOfDay? _filterEndTime;
  String _selectedStatusFilter = 'ALL';

  bool _isLoading = true;
  final Set<int> _expandedTaskIds = <int>{};

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    try {
      final results = await Future.wait([
        _service.fetchAllTasks(),
        _reportService.fetchAllReports(),
        _service.fetchEnvironmentTeamLeads(),
      ]);

      final tasks = (results[0] as List<EnvironmentCleanupTask>)
        ..sort((a, b) => b.assignedAt.compareTo(a.assignedAt));
      final reports = results[1] as List<Report>;
      final teamLeads = results[2] as List<EnvironmentTeamLead>;

      final assignedReportIds = tasks
          .where((task) => task.status != 'RESOLVED')
          .map((task) => task.reportId)
          .toSet();

      final assignableReports = reports
          .where(
            (report) =>
                report.status == 'VERIFIED' &&
                !assignedReportIds.contains(report.reportId),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _assignableReports = assignableReports;
        _teamLeads = teamLeads;

        if (_selectedReportId != null &&
            !_assignableReports.any((report) => report.reportId == _selectedReportId)) {
          _selectedReportId = null;
        }
        if (_selectedTeamLeadId != null &&
            !_teamLeads.any((teamLead) => teamLead.userId == _selectedTeamLeadId)) {
          _selectedTeamLeadId = null;
        }

        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _assignTask() async {
    if (_selectedReportId == null || _selectedTeamLeadId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn report và team lead.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_startDate == null ||
        _startTime == null ||
        _endDate == null ||
        _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Vui lòng chọn đủ ngày thực hiện, giờ bắt đầu, ngày kết thúc và giờ kết thúc.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final startAt = _composeDateTime(_startDate!, _startTime!);
    final endAt = _composeDateTime(_endDate!, _endTime!);

    if (!endAt.isAfter(startAt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời gian kết thúc phải sau thời gian bắt đầu.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _service.assignTask(
        reportId: _selectedReportId!,
        teamLeadUserId: _selectedTeamLeadId!,
        assignmentNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
        plannedStartAt: startAt.toIso8601String(),
        plannedEndAt: endAt.toIso8601String(),
        dueAt: endAt.toIso8601String(),
      );

      _selectedReportId = null;
      _selectedTeamLeadId = null;
      _startDate = null;
      _startTime = null;
      _endDate = null;
      _endTime = null;
      _noteCtrl.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phân công thành công.')),
      );
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _resolveTask(int taskId) async {
    try {
      await _service.resolveTask(taskId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xác nhận hoàn tất xử lý.')),
      );
      await _loadTasks();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  List<EnvironmentCleanupTask> get _filteredTasks {
    final start = _composeBoundaryDateTime(
      _filterStartDate,
      _filterStartTime,
      isEndBoundary: false,
    );
    final end = _composeBoundaryDateTime(
      _filterEndDate,
      _filterEndTime,
      isEndBoundary: true,
    );

    return _tasks.where((task) {
      final assignedAt = task.assignedAt;
      final afterStart = start == null || !assignedAt.isBefore(start);
      final beforeEnd = end == null || !assignedAt.isAfter(end);
      final normalizedStatus = _normalizedStatusKey(task.status);
      final matchesStatus =
          _selectedStatusFilter == 'ALL' || normalizedStatus == _selectedStatusFilter;
      return afterStart && beforeEnd && matchesStatus;
    }).toList();
  }

  List<String> get _availableStatusFilters {
    final statuses = _tasks
        .map((task) => _normalizedStatusKey(task.status))
        .toSet();
    final ordered = <String>['ALL'];

    for (final status in const [
      'PENDING',
      'CLEANED_PENDING_CONFIRM',
      'RESOLVED',
    ]) {
      if (statuses.contains(status)) {
        ordered.add(status);
      }
    }

    final remaining = statuses.where((status) => !ordered.contains(status)).toList()
      ..sort();
    ordered.addAll(remaining);
    return ordered;
  }

  String _normalizedStatusKey(String status) {
    switch (status) {
      case 'RESOLVED':
        return 'RESOLVED';
      case 'CLEANED_PENDING_CONFIRM':
        return 'CLEANED_PENDING_CONFIRM';
      default:
        return 'PENDING';
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ALL':
        return 'Tất cả';
      case 'PENDING':
        return 'Chờ xử lý';
      case 'CLEANED_PENDING_CONFIRM':
        return 'Chờ xác nhận';
      case 'RESOLVED':
        return 'Đã hoàn tất';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'PENDING':
        return AppColors.adminAccentSky;
      case 'CLEANED_PENDING_CONFIRM':
        return AppColors.adminAccentWarm;
      case 'RESOLVED':
        return AppColors.adminAccent;
      default:
        return AppColors.adminAccentDeep;
    }
  }

  DateTime _composeDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  DateTime? _composeBoundaryDateTime(
    DateTime? date,
    TimeOfDay? time, {
    required bool isEndBoundary,
  }) {
    if (date == null && time == null) return null;
    if (date == null) return null;

    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? (isEndBoundary ? 23 : 0),
      time?.minute ?? (isEndBoundary ? 59 : 0),
    );
  }

  void _clearFilters() {
    setState(() {
      _filterStartDate = null;
      _filterStartTime = null;
      _filterEndDate = null;
      _filterEndTime = null;
      _selectedStatusFilter = 'ALL';
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleTasks = _filteredTasks;
    final waitingConfirmCount = _tasks.where((task) => task.status == 'CLEANED_PENDING_CONFIRM').length;
    final resolvedCount = _tasks.where((task) => task.status == 'RESOLVED').length;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1320),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
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
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Phân Công Đội Môi Trường',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: AppColors.adminTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Điều phối đội môi trường xử lý các báo cáo đã xác minh.',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.adminTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _summaryCard('Tổng task', _tasks.length.toString(), Icons.assignment_turned_in_outlined, AppColors.adminAccent),
                          _summaryCard('Chờ xác nhận', waitingConfirmCount.toString(), Icons.hourglass_top_rounded, AppColors.adminAccentSky),
                          _summaryCard('Đã hoàn tất', resolvedCount.toString(), Icons.verified_rounded, AppColors.adminAccentWarm),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _sectionTitle('Lập phân công mới'),
                      _assignmentForm(),
                      const SizedBox(height: 16),
                      _sectionTitle('Lọc theo ngày giờ'),
                      _filterPanel(),
                      const SizedBox(height: 16),
                      _sectionTitle('Danh sách task đã phân công'),
                      const SizedBox(height: 12),
                      _isLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 40),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : visibleTasks.isEmpty
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text('Chưa có công việc môi trường nào.'),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: visibleTasks.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (_, index) => _taskCard(visibleTasks[index]),
                                ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 22,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.adminAccent, AppColors.adminAccentSky],
              ),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.adminTextPrimary,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminSurface,
            color.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.adminTextSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.adminTextPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _assignmentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminSurface,
            AppColors.adminSurfaceSoft,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
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
          final isWide = constraints.maxWidth >= 980;
          final halfWidth = isWide
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;
          final compactWidth = isWide
              ? (constraints.maxWidth - 12) / 2
              : constraints.maxWidth;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _reportDropdown(width: halfWidth),
                  _teamLeadDropdown(width: halfWidth),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _datePickerField(
                    label: 'Ngày thực hiện',
                    value: _startDate,
                    icon: Icons.event_available_outlined,
                    onPressed: _pickStartDate,
                    width: compactWidth,
                  ),
                  _timePickerField(
                    label: 'Giờ bắt đầu',
                    value: _startTime,
                    icon: Icons.schedule,
                    onPressed: _pickStartTime,
                    width: compactWidth,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _datePickerField(
                    label: 'Ngày kết thúc',
                    value: _endDate,
                    icon: Icons.event_busy_outlined,
                    onPressed: _pickEndDate,
                    width: compactWidth,
                  ),
                  _timePickerField(
                    label: 'Giờ kết thúc',
                    value: _endTime,
                    icon: Icons.av_timer_outlined,
                    onPressed: _pickEndTime,
                    width: compactWidth,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _inputField(_noteCtrl, 'Ghi chú phân công', maxWidth: compactWidth),
                  ElevatedButton.icon(
                    onPressed: _assignTask,
                    icon: const Icon(Icons.assignment_ind),
                    label: const Text('Phân công'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.adminAccentDeep,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(170, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 4,
                      shadowColor: AppColors.adminAccentDeep.withValues(alpha: 0.28),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterPanel() {
    final statusSuffix = _selectedStatusFilter == 'ALL'
      ? ''
      : ' · Trạng thái: ${_statusLabel(_selectedStatusFilter)}';
    final hasActiveFilter = _filterStartDate != null ||
        _filterStartTime != null ||
        _filterEndDate != null ||
      _filterEndTime != null ||
      _selectedStatusFilter != 'ALL';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.adminSurface,
            Color(0xFFF4FBF8),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasActiveFilter ? AppColors.adminAccent : AppColors.adminBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _datePickerField(
                label: 'Từ ngày',
                value: _filterStartDate,
                icon: Icons.date_range_outlined,
                onPressed: _pickFilterStartDate,
                width: 185,
                height: 40,
                placeholder: 'Chọn',
              ),
              _timePickerField(
                label: 'Từ giờ',
                value: _filterStartTime,
                icon: Icons.schedule,
                onPressed: _pickFilterStartTime,
                width: 185,
                height: 40,
                placeholder: 'Chọn',
              ),
              _datePickerField(
                label: 'Đến ngày',
                value: _filterEndDate,
                icon: Icons.date_range_outlined,
                onPressed: _pickFilterEndDate,
                width: 185,
                height: 40,
                placeholder: 'Chọn',
              ),
              _timePickerField(
                label: 'Đến giờ',
                value: _filterEndTime,
                icon: Icons.schedule,
                onPressed: _pickFilterEndTime,
                width: 185,
                height: 40,
                placeholder: 'Chọn',
              ),
              _statusFilterField(width: 185, height: 40),
              ElevatedButton.icon(
                onPressed: hasActiveFilter ? _clearFilters : null,
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Xóa lọc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.adminAccentWarm,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(116, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasActiveFilter
                ? 'Đang lọc ${_filteredTasks.length}/${_tasks.length} task$statusSuffix'
                : 'Hiển thị toàn bộ task đã phân công',
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamLeadDropdown({double width = 320}) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        value: _selectedTeamLeadId,
        isExpanded: true,
        decoration: _fieldDecoration('Chọn Team Lead môi trường'),
        hint: Text(
          _teamLeads.isEmpty ? 'Không có team lead khả dụng' : 'Chọn team lead',
        ),
        items: _teamLeads
            .map(
              (u) => DropdownMenuItem<int>(
                value: u.userId,
                child: Text(
                  '#${u.userId} - ${u.fullName}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _teamLeads.isEmpty
            ? null
            : (value) {
                setState(() => _selectedTeamLeadId = value);
              },
      ),
    );
  }

  Widget _statusFilterField({double width = 185, double height = 40}) {
    final statuses = _availableStatusFilters;
    final selectedValue = statuses.contains(_selectedStatusFilter)
        ? _selectedStatusFilter
        : 'ALL';

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.adminBorderStrong),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: AppColors.adminAccentDeep,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.adminAccentDeep,
                fontWeight: FontWeight.w500,
              ),
              items: statuses
                  .map(
                    (status) => DropdownMenuItem<String>(
                      value: status,
                      child: Text(
                        'Trạng thái: ${_statusLabel(status)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() => _selectedStatusFilter = value);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onPressed,
    double width = 240,
    double height = 52,
    String placeholder = 'Chọn ngày',
  }) {
    final text = value == null ? placeholder : DateFormat('dd/MM/yyyy').format(value);
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          '$label: $text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.adminAccentDeep,
          side: const BorderSide(color: AppColors.adminBorderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
      ),
    );
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required IconData icon,
    required VoidCallback onPressed,
    double width = 220,
    double height = 52,
    String placeholder = 'Chọn giờ',
  }) {
    final text = value == null ? placeholder : value.format(context);
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          '$label: $text',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.adminAccentDeep,
          side: const BorderSide(color: AppColors.adminBorderStrong),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
        ),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _endDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _startTime = picked);
  }

  Future<void> _pickEndTime() async {
    final initialHour = ((_startTime?.hour ?? TimeOfDay.now().hour) + 1) % 24;
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay(hour: initialHour, minute: _startTime?.minute ?? 0),
    );
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  Future<void> _pickFilterStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _filterStartDate = picked);
  }

  Future<void> _pickFilterEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _filterEndDate ?? _filterStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _filterEndDate = picked);
  }

  Future<void> _pickFilterStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _filterStartTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _filterStartTime = picked);
  }

  Future<void> _pickFilterEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _filterEndTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => _filterEndTime = picked);
  }

  Widget _reportDropdown({double width = 320}) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<int>(
        value: _selectedReportId,
        isExpanded: true,
        decoration: _fieldDecoration('Chọn Report cần xử lý'),
        hint: Text(
          _assignableReports.isEmpty
              ? 'Không có report VERIFIED khả dụng'
              : 'Chọn report',
        ),
        items: _assignableReports
            .map(
              (r) => DropdownMenuItem<int>(
                value: r.reportId,
                child: Text(
                  '#${r.reportId} - ${r.title}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: _assignableReports.isEmpty
            ? null
            : (value) {
                setState(() => _selectedReportId = value);
              },
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String label, {
    double maxWidth = 250,
  }) {
    return SizedBox(
      width: maxWidth,
      child: TextField(
        controller: controller,
        decoration: _fieldDecoration(label),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppColors.adminSurfaceSoft,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.adminBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.adminBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.adminAccent, width: 1.5),
      ),
    );
  }

  Widget _taskCard(EnvironmentCleanupTask task) {
    final canResolve = task.status == 'CLEANED_PENDING_CONFIRM';
    final isExpanded = _expandedTaskIds.contains(task.taskId);
    final normalizedStatus = _normalizedStatusKey(task.status);
    final statusColor = _statusColor(normalizedStatus);
    final statusLabel = _statusLabel(normalizedStatus);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.adminBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
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
                    Text(
                      'Task #${task.taskId}',
                      style: const TextStyle(
                        color: AppColors.adminTextSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      task.reportTitle,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 22,
                        color: AppColors.adminTextPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Report ID: ${task.reportId}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.adminTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedTaskIds.remove(task.taskId);
                        } else {
                          _expandedTaskIds.add(task.taskId);
                        }
                      });
                    },
                    icon: Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    ),
                    label: Text(isExpanded ? 'Thu gọn' : 'Xem thêm'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.adminAccentDeep,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _taskMetaChip(
                icon: Icons.access_time_rounded,
                label: 'Giao lúc: ${DateFormat("dd/MM/yyyy HH:mm").format(task.assignedAt)}',
              ),
              _taskMetaChip(
                icon: Icons.play_circle_outline_rounded,
                label: task.plannedStartAt == null
                    ? 'Bắt đầu: Chưa đặt'
                    : 'Bắt đầu: ${DateFormat("dd/MM/yyyy HH:mm").format(task.plannedStartAt!)}',
              ),
              _taskMetaChip(
                icon: Icons.flag_outlined,
                label: task.plannedEndAt == null
                    ? 'Kết thúc: Chưa đặt'
                    : 'Kết thúc: ${DateFormat("dd/MM/yyyy HH:mm").format(task.plannedEndAt!)}',
              ),
            ],
          ),
          if (isExpanded) ...[
            const SizedBox(height: 14),
            if (task.assignmentNote.isNotEmpty)
              Text(
                'Ghi chú: ${task.assignmentNote}',
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  height: 1.4,
                ),
              ),
            if (task.afterImageUrl.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Ảnh hiện trường sau xử lý',
                style: TextStyle(
                  color: Color(0xFF166534),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              _imagePreviewBox(task.afterImageUrl, height: 220),
            ],
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showTaskDetailDialog(task),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Xem chi tiết'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.adminBorderStrong),
                  foregroundColor: AppColors.adminTextPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              if (canResolve)
                ElevatedButton(
                  onPressed: () => _resolveTask(task.taskId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.adminAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text('Xác nhận RESOLVED'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _taskMetaChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.adminSurfaceSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.adminAccentDeep),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetailDialog(EnvironmentCleanupTask task) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Text('Chi tiết Task #${task.taskId}'),
          content: SizedBox(
            width: 580,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailLine('Tiêu đề', task.reportTitle),
                  _detailLine('Report ID', '${task.reportId}'),
                  _detailLine('Category', task.reportCategory),
                  _detailLine('Trạng thái task', task.status),
                  _detailLine('Trạng thái report', task.reportStatus),
                  _detailLine('Giao lúc', DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt)),
                  _detailLine(
                    'Bắt đầu thực hiện',
                    task.plannedStartAt == null
                        ? 'Chưa đặt'
                        : DateFormat('HH:mm dd/MM/yyyy').format(task.plannedStartAt!),
                  ),
                  _detailLine(
                    'Kết thúc task',
                    task.plannedEndAt == null
                        ? 'Chưa đặt'
                        : DateFormat('HH:mm dd/MM/yyyy').format(task.plannedEndAt!),
                  ),
                  _detailLine(
                    'Ghi chú phân công',
                    task.assignmentNote.isEmpty ? 'Không có' : task.assignmentNote,
                  ),
                  _detailLine(
                    'Ảnh sau xử lý',
                    task.afterImageUrl.isEmpty ? 'Chưa có' : task.afterImageUrl,
                  ),
                  if (task.afterImageUrl.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _imagePreviewBox(task.afterImageUrl, height: 220),
                    ),
                  _detailLine(
                    'Báo cáo hiện trường',
                    task.completedNote.isEmpty ? 'Chưa có' : task.completedNote,
                  ),
                  _detailLine(
                    'Hoàn tất lúc',
                    task.completedAt == null
                        ? 'Chưa hoàn tất'
                        : DateFormat('HH:mm dd/MM/yyyy').format(task.completedAt!),
                  ),
                  _detailLine(
                    'Admin duyệt lúc',
                    task.resolvedAt == null
                        ? 'Chưa duyệt'
                        : DateFormat('HH:mm dd/MM/yyyy').format(task.resolvedAt!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 14),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _imagePreviewBox(String imageUrl, {double height = 180}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: height),
        color: const Color(0xFFF3F4F6),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => SizedBox(
            height: height,
            child: const Center(child: Text('Không tải được ảnh')),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return SizedBox(
              height: height,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        ),
      ),
    );
  }
}
