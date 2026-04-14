import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_empty_state.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_summary_card.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/widgets/environment_task_card.dart';

class EnvironmentOverviewTab extends StatelessWidget {
  final List<EnvironmentCleanupTask> tasks;
  final bool isLoading;
  final Future<void> Function() onRefresh;
  final void Function(EnvironmentCleanupTask task) onOpenTaskDetailPage;
  final void Function(EnvironmentCleanupTask task) onOpenTaskNavigationMap;
  final void Function(EnvironmentCleanupTask task) onOpenTaskReportPage;

  const EnvironmentOverviewTab({
    super.key,
    required this.tasks,
    required this.isLoading,
    required this.onRefresh,
    required this.onOpenTaskDetailPage,
    required this.onOpenTaskNavigationMap,
    required this.onOpenTaskReportPage,
  });

  @override
  Widget build(BuildContext context) {
    final assigned = tasks.where((task) => task.status == 'ASSIGNED').length;
    final waitingConfirm = tasks
        .where((task) => task.status == 'CLEANED_PENDING_CONFIRM')
        .length;
    final resolved = tasks.where((task) => task.status == 'RESOLVED').length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6DBB3B), Color(0xFF2F6F3E)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2F6F3E).withOpacity(0.18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.eco_outlined,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Giữ thành phố sạch hơn',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Xử lý nhanh, báo cáo chính xác',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: EnvironmentSummaryCard(
                  label: 'Đang giao',
                  value: '$assigned',
                  icon: Icons.pending_actions_outlined,
                  color: const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnvironmentSummaryCard(
                  label: 'Chờ duyệt',
                  value: '$waitingConfirm',
                  icon: Icons.verified_outlined,
                  color: const Color(0xFF3B82F6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: EnvironmentSummaryCard(
                  label: 'Hoàn tất',
                  value: '$resolved',
                  icon: Icons.check_circle_outline,
                  color: const Color(0xFF16A34A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: EnvironmentSummaryCard(
                  label: 'Tổng việc',
                  value: '${tasks.length}',
                  icon: Icons.assignment_outlined,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Việc gần nhất',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: const Color(0xFF1F2D1D),
            ),
          ),
          const SizedBox(height: 12),
          if (isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (tasks.isEmpty)
            const EnvironmentEmptyState(
              text: 'Chưa có công việc nào được giao.',
            )
          else
            EnvironmentTaskCard(
              task: tasks.first,
              onViewDetails: () => onOpenTaskDetailPage(tasks.first),
              onNavigateToTask: () => onOpenTaskNavigationMap(tasks.first),
              onSubmitCompletion: () => onOpenTaskReportPage(tasks.first),
            ),
        ],
      ),
    );
  }
}
