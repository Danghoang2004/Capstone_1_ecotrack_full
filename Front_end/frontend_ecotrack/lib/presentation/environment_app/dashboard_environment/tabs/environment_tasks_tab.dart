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
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<EnvironmentCleanupTask> _filteredTasks() {
    var tasks = widget.tasks;

    // Apply status filter
    switch (_selectedFilter) {
      case _TaskFilter.assigned:
        tasks = tasks.where((task) => task.status == 'ASSIGNED').toList();
        break;
      case _TaskFilter.pending:
        tasks = tasks
            .where((task) => task.status == 'CLEANED_PENDING_CONFIRM')
            .toList();
        break;
      case _TaskFilter.resolved:
        tasks = tasks.where((task) => task.status == 'RESOLVED').toList();
        break;
      case _TaskFilter.unfinished:
        tasks = tasks.where((task) => task.status != 'RESOLVED').toList();
        break;
      case _TaskFilter.all:
        break;
    }

    // Apply search filter
    final searchText = _searchController.text.toLowerCase();
    if (searchText.isNotEmpty) {
      tasks = tasks.where((task) {
        return task.reportTitle.toLowerCase().contains(searchText) ||
            task.reportId.toString().contains(searchText) ||
            task.reportCategory.toLowerCase().contains(searchText);
      }).toList();
    }

    return tasks;
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

  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final mediaQuery = MediaQuery.of(context);
        final maxSheetHeight = mediaQuery.size.height * 0.62;

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              12 + mediaQuery.viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lọc công việc',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2D1D),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.close, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Theo trạng thái',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2D1D),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Flexible(
                    fit: FlexFit.loose,
                    child: SingleChildScrollView(
                      child: Column(
                        children: _TaskFilter.values.map((filter) {
                          final isSelected = _selectedFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: GestureDetector(
                              onTap: () {
                                setState(() => _selectedFilter = filter);
                                Navigator.pop(context);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(
                                          0xFF5EAC24,
                                        ).withOpacity(0.14)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(
                                          color: const Color(0xFF5EAC24),
                                          width: 2,
                                        )
                                      : Border.all(color: Colors.transparent),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected
                                              ? const Color(0xFF5EAC24)
                                              : Colors.grey.shade400,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: Color(0xFF5EAC24),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      _labelForFilter(filter),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? const Color(0xFF2F6F3E)
                                            : Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5EAC24),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Xong',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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
            'Theo dõi tiến độ và báo cáo hoàn tất từng điểm xử lý.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Search Bar + Filter Button
          Row(
            children: [
              Expanded(
                child: Container(
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
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm theo tên, mã báo cáo...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() {});
                              },
                              child: Icon(
                                Icons.close,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
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
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _showFilterModal(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Icon(
                        Icons.tune_outlined,
                        color: Colors.grey.shade700,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Hiển thị ${filteredTasks.length}/${widget.tasks.length} công việc',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
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
