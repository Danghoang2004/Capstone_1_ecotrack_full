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
    final canSubmit = task.status == 'ASSIGNED' && task.canSubmitCompletion;

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 14,
            offset: const Offset(0, 5),
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
                      task.reportTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1F2D1D),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mã báo cáo: #${task.reportId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _infoLine(Icons.access_time, 'Giao lúc',
                    DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt)),
                const SizedBox(height: 8),
                _infoLine(Icons.event_outlined, 'Lịch xử lý',
                    _plannedRangeText(task)),
              ],
            ),
          ),
          if (task.assignmentNote.isNotEmpty) ...[
            const SizedBox(height: 10),
            _infoLine(Icons.notes_outlined, 'Ghi chú', task.assignmentNote,
                maxLines: 2),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.open_in_new_outlined, size: 16),
                label: const Text('Xem đầy đủ'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFFD7E7D1)),
                  foregroundColor: Colors.black,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onNavigateToTask,
                icon: const Icon(Icons.near_me_outlined, size: 16),
                label: const Text('Chỉ đường'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  side: const BorderSide(color: Color(0xFFD7E7D1)),
                  foregroundColor: Colors.black,
                ),
              ),
              if (canSubmit && onSubmitCompletion != null)
                ElevatedButton.icon(
                  onPressed: onSubmitCompletion,
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Báo cáo'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5EAC24),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
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
    return '$start → $end';
  }

  Widget _infoLine(
    IconData icon,
    String label,
    String value, {
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF5EAC24)),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 12,
              color: Color(0xFF1F2D1D),
            ),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
