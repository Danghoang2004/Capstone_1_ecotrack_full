import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_empty_state.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_task_card.dart';

enum _TaskFilter { all, assigned, pending, resolved, unfinished }

class EnvironmentTasksTab extends StatefulWidget {
  final List<EnvironmentCleanupTask> tasks;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(EnvironmentCleanupTask task) onOpenTaskDetailPage;
  final void Function(EnvironmentCleanupTask task) onOpenTaskNavigationMap;
  final void Function(EnvironmentCleanupTask task) onOpenTaskReportPage;

  const EnvironmentTasksTab({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenTaskDetailPage,
    required this.onOpenTaskNavigationMap,
    required this.onOpenTaskReportPage,
  });

  @override
  State<EnvironmentTasksTab> createState() => _EnvironmentTasksTabState();
}

class _EnvironmentTasksTabState extends State<EnvironmentTasksTab> {
  _TaskFilter _selectedFilter = _TaskFilter.all;

  List<EnvironmentCleanupTask> _filteredTasks() {
    switch (_selectedFilter) {
      case _TaskFilter.assigned:
        return widget.tasks.where((task) => task.status == 'ASSIGNED').toList();
      case _TaskFilter.pending:
        return widget.tasks
            .where((task) => task.status == 'CLEANED_PENDING_CONFIRM')
            .toList();
      case _TaskFilter.resolved:
        return widget.tasks.where((task) => task.status == 'RESOLVED').toList();
      case _TaskFilter.unfinished:
        return widget.tasks.where((task) => task.status != 'RESOLVED').toList();
      case _TaskFilter.all:
        return widget.tasks;
    }
  }

  String _labelForFilter(_TaskFilter filter) {
    switch (filter) {
      case _TaskFilter.all:
        return 'Tất cả';
      case _TaskFilter.assigned:
        return 'Được giao';
      case _TaskFilter.pending:
        return 'Chờ duyệt';
      case _TaskFilter.resolved:
        return 'Hoàn thành';
      case _TaskFilter.unfinished:
        return 'Chưa xong';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredTasks = _filteredTasks();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Danh sách công việc',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Theo dõi tiến độ và báo cáo hoàn tất từng điểm xử lý.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _TaskFilter.values.map((filter) {
              return FilterChip(
                label: Text(_labelForFilter(filter)),
                selected: _selectedFilter == filter,
                onSelected: (_) => setState(() => _selectedFilter = filter),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Hiển thị ${filteredTasks.length}/${widget.tasks.length} công việc',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          if (widget.isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (filteredTasks.isEmpty)
            const EnvironmentEmptyState(text: 'Không có nhiệm vụ để hiển thị.')
          else
            ...filteredTasks.map(
              (task) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: EnvironmentTaskCard(
                  task: task,
                  onViewDetails: () => widget.onOpenTaskDetailPage(task),
                  onNavigateToTask: () => widget.onOpenTaskNavigationMap(task),
                  onSubmitCompletion: () => widget.onOpenTaskReportPage(task),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
