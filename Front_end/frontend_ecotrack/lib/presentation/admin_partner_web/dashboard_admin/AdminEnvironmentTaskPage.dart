import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/admin_environment_task_service.dart';
import 'package:frontend_ecotrack/core/services/ReportService.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/data/models/report_model.dart';
import 'package:frontend_ecotrack/data/models/environment_team_lead_model.dart';
import 'package:intl/intl.dart';

class AdminEnvironmentTaskPage extends StatefulWidget {
  const AdminEnvironmentTaskPage({super.key});

  @override
  State<AdminEnvironmentTaskPage> createState() =>
      _AdminEnvironmentTaskPageState();
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
  bool _isLoading = true;

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

      final tasks = results[0] as List<EnvironmentCleanupTask>;
      final reports = results[1] as List<Report>;
      final teamLeads = results[2] as List<EnvironmentTeamLead>;

      final assignedReportIds = tasks
          .where((t) => t.status != 'RESOLVED')
          .map((t) => t.reportId)
          .toSet();

      final assignableReports = reports
          .where(
            (r) =>
                r.status == 'VERIFIED' &&
                !assignedReportIds.contains(r.reportId),
          )
          .toList();

      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _assignableReports = assignableReports;
        _teamLeads = teamLeads;
        if (_selectedReportId != null &&
            !_assignableReports.any((r) => r.reportId == _selectedReportId)) {
          _selectedReportId = null;
        }
        if (_selectedTeamLeadId != null &&
            !_teamLeads.any((t) => t.userId == _selectedTeamLeadId)) {
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
        assignmentNote: _noteCtrl.text.trim().isEmpty
            ? null
            : _noteCtrl.text.trim(),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Phân công thành công.')));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Phân Công Đội Môi Trường',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _assignmentForm(),
            const SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _tasks.isEmpty
                  ? const Center(
                      child: Text('Chưa có công việc môi trường nào.'),
                    )
                  : ListView.separated(
                      itemCount: _tasks.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) => _taskCard(_tasks[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _assignmentForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _reportDropdown(),
          _teamLeadDropdown(),
          _datePickerField(
            label: 'Ngày thực hiện',
            value: _startDate,
            icon: Icons.event_available_outlined,
            onPressed: _pickStartDate,
          ),
          _timePickerField(
            label: 'Giờ bắt đầu',
            value: _startTime,
            icon: Icons.schedule,
            onPressed: _pickStartTime,
          ),
          _datePickerField(
            label: 'Ngày kết thúc',
            value: _endDate,
            icon: Icons.event_busy_outlined,
            onPressed: _pickEndDate,
          ),
          _timePickerField(
            label: 'Giờ kết thúc',
            value: _endTime,
            icon: Icons.av_timer_outlined,
            onPressed: _pickEndTime,
          ),
          _inputField(_noteCtrl, 'Ghi chú phân công', maxWidth: 360),
          ElevatedButton.icon(
            onPressed: _assignTask,
            icon: const Icon(Icons.assignment_ind),
            label: const Text('Phân công'),
          ),
        ],
      ),
    );
  }

  Widget _teamLeadDropdown() {
    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<int>(
        value: _selectedTeamLeadId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chọn Team Lead môi trường',
          border: OutlineInputBorder(),
        ),
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

  Widget _datePickerField({
    required String label,
    required DateTime? value,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final text = value == null
        ? 'Chọn ngày'
        : DateFormat('dd/MM/yyyy').format(value);
    return SizedBox(
      width: 240,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text('$label: $text'),
      ),
    );
  }

  Widget _timePickerField({
    required String label,
    required TimeOfDay? value,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final text = value == null ? 'Chọn giờ' : value.format(context);
    return SizedBox(
      width: 220,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text('$label: $text'),
      ),
    );
  }

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final initial = _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final now = DateTime.now();
    final initial = _endDate ?? _startDate ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
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
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _endTime ??
          TimeOfDay(
            hour: (_startTime?.hour ?? TimeOfDay.now().hour + 1) % 24,
            minute: _startTime?.minute ?? TimeOfDay.now().minute,
          ),
    );
    if (picked == null || !mounted) return;
    setState(() => _endTime = picked);
  }

  DateTime _composeDateTime(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _reportDropdown() {
    return SizedBox(
      width: 320,
      child: DropdownButtonFormField<int>(
        value: _selectedReportId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Chọn Report cần xử lý',
          border: OutlineInputBorder(),
        ),
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
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _taskCard(EnvironmentCleanupTask task) {
    final canResolve = task.status == 'CLEANED_PENDING_CONFIRM';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Task #${task.taskId} - ${task.reportTitle}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: canResolve
                      ? Colors.blue.withOpacity(0.2)
                      : Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(task.status),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Report ID: ${task.reportId}'),
          Text(
            'Giao lúc: ${DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt)}',
          ),
          Text(
            'Bắt đầu thực hiện: ${task.plannedStartAt == null ? 'Chưa đặt' : DateFormat('HH:mm dd/MM/yyyy').format(task.plannedStartAt!)}',
          ),
          Text(
            'Kết thúc task: ${task.plannedEndAt == null ? 'Chưa đặt' : DateFormat('HH:mm dd/MM/yyyy').format(task.plannedEndAt!)}',
          ),
          if (task.afterImageUrl.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ảnh hiện trường sau xử lý',
                  style: TextStyle(
                    color: Color(0xFF166534),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                _imagePreviewBox(task.afterImageUrl, height: 140),
              ],
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _showTaskDetailDialog(task),
                icon: const Icon(Icons.visibility_outlined),
                label: const Text('Xem chi tiết'),
              ),
              const SizedBox(width: 10),
              if (canResolve)
                ElevatedButton(
                  onPressed: () => _resolveTask(task.taskId),
                  child: const Text('Xác nhận RESOLVED'),
                ),
            ],
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
                  _detailLine(
                    'Giao lúc',
                    DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt),
                  ),
                  _detailLine(
                    'Bắt đầu thực hiện',
                    task.plannedStartAt == null
                        ? 'Chưa đặt'
                        : DateFormat(
                            'HH:mm dd/MM/yyyy',
                          ).format(task.plannedStartAt!),
                  ),
                  _detailLine(
                    'Kết thúc task',
                    task.plannedEndAt == null
                        ? 'Chưa đặt'
                        : DateFormat(
                            'HH:mm dd/MM/yyyy',
                          ).format(task.plannedEndAt!),
                  ),
                  _detailLine(
                    'Ghi chú phân công',
                    task.assignmentNote.isEmpty
                        ? 'Không có'
                        : task.assignmentNote,
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
                        : DateFormat(
                            'HH:mm dd/MM/yyyy',
                          ).format(task.completedAt!),
                  ),
                  _detailLine(
                    'Admin duyệt lúc',
                    task.resolvedAt == null
                        ? 'Chưa duyệt'
                        : DateFormat(
                            'HH:mm dd/MM/yyyy',
                          ).format(task.resolvedAt!),
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
