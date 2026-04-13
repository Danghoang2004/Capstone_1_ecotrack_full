import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:intl/intl.dart';

class EnvironmentTaskCard extends StatelessWidget {
  final EnvironmentCleanupTask task;
  final VoidCallback? onViewDetails;
  final VoidCallback? onNavigateToTask;
  final VoidCallback? onSubmitCompletion;

  const EnvironmentTaskCard({
    super.key,
    required this.task,
    this.onViewDetails,
    this.onNavigateToTask,
    this.onSubmitCompletion,
  });

  @override
  Widget build(BuildContext context) {
    final canSubmit = task.status == 'ASSIGNED' && onSubmitCompletion != null;

    final statusColor = switch (task.status) {
      'ASSIGNED' => const Color(0xFFF59E0B),
      'CLEANED_PENDING_CONFIRM' => const Color(0xFF3B82F6),
      'RESOLVED' => const Color(0xFF16A34A),
      _ => Colors.grey,
    };

    final statusLabel = switch (task.status) {
      'ASSIGNED' => 'Đang chờ xử lý',
      'CLEANED_PENDING_CONFIRM' => 'Chờ admin duyệt',
      'RESOLVED' => 'Đã hoàn tất',
      _ => task.status,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.reportTitle,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoLine(Icons.tag_outlined, 'Mã báo cáo', '#${task.reportId}'),
          _infoLine(
            Icons.access_time,
            'Giao lúc',
            DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt),
          ),
          _infoLine(
            Icons.event_outlined,
            'Lịch xử lý',
            _plannedRangeText(task),
          ),
          if (task.assignmentNote.isNotEmpty)
            _infoLine(
              Icons.notes_outlined,
              'Ghi chú',
              task.assignmentNote,
              maxLines: 2,
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new_outlined),
                label: const Text('Xem đầy đủ'),
              ),
              OutlinedButton.icon(
                onPressed: onNavigateToTask,
                icon: const Icon(Icons.near_me_outlined),
                label: const Text('Chỉ đường'),
              ),
              if (canSubmit) ...[
                ElevatedButton.icon(
                  onPressed: onSubmitCompletion,
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Báo cáo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EAC24),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _plannedRangeText(EnvironmentCleanupTask task) {
    if (task.plannedStartAt == null && task.plannedEndAt == null) {
      return 'Chưa đặt';
    }

    final start = task.plannedStartAt == null
        ? '--'
        : DateFormat('HH:mm dd/MM').format(task.plannedStartAt!);
    final end = task.plannedEndAt == null
        ? '--'
        : DateFormat('HH:mm dd/MM').format(task.plannedEndAt!);
    return '$start -> $end';
  }

  Widget _infoLine(
    IconData icon,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
