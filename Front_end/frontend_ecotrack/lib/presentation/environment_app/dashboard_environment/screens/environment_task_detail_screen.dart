import 'package:flutter/material.dart';
import 'package:frontend_ecotrack/core/services/environment_task_service.dart';
import 'package:frontend_ecotrack/data/models/environment_cleanup_task_model.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_navigation_map_screen.dart';
import 'package:frontend_ecotrack/presentation/environment_app/dashboard_environment/screens/environment_task_report_screen.dart';
import 'package:intl/intl.dart';

class EnvironmentTaskDetailScreen extends StatelessWidget {
  final EnvironmentCleanupTask task;

  const EnvironmentTaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final canSubmitCompletion =
        task.status == 'ASSIGNED' && task.canSubmitCompletion;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Chi tiết task #${task.taskId}'),
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1F2D1D),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            icon: Icons.assignment_outlined,
            title: task.reportTitle,
            child: Column(
              children: [
                _detailRow('Mã báo cáo', '#${task.reportId}'),
                _detailRow('Trạng thái task', _statusLabel(task.status)),
                _detailRow('Trạng thái báo cáo', task.reportStatus),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      double? destLat = task.reportGpsLat;
                      double? destLong = task.reportGpsLong;

                      if (destLat == null || destLong == null) {
                        final service = EnvironmentTaskService();
                        final fallback = await service
                            .fetchTaskDestinationByReportId(task.reportId);
                        if (fallback != null) {
                          destLat = fallback.latitude;
                          destLong = fallback.longitude;
                        }
                      }

                      if (destLat == null || destLong == null) {
                        if (!context.mounted) return;
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

                      if (!context.mounted) return;
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EnvironmentTaskNavigationMapScreen(
                            taskTitle: task.reportTitle,
                            destinationLat: destLat!,
                            destinationLong: destLong!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.near_me_outlined, size: 16),
                    label: const Text('Chỉ đường tới điểm xử lý'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: Icons.schedule_outlined,
            title: 'Thời gian',
            child: Column(
              children: [
                _detailRow(
                  'Giao lúc',
                  DateFormat('HH:mm dd/MM/yyyy').format(task.assignedAt),
                ),
                _detailRow(
                  'Bắt đầu dự kiến',
                  _formatDateTime(task.plannedStartAt),
                ),
                _detailRow(
                  'Kết thúc dự kiến',
                  _formatDateTime(task.plannedEndAt),
                ),
                _detailRow('Hạn hoàn tất', _formatDateTime(task.dueAt)),
                _detailRow('Hoàn tất lúc', _formatDateTime(task.completedAt)),
                _detailRow('Duyệt lúc', _formatDateTime(task.resolvedAt)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSection(
            icon: Icons.description_outlined,
            title: 'Nội dung',
            child: Column(
              children: [
                _detailRow(
                  'Ghi chú phân công',
                  task.assignmentNote.isEmpty
                      ? 'Không có'
                      : task.assignmentNote,
                  multiLine: true,
                ),
                _detailRow(
                  'Báo cáo hiện trường',
                  task.completedNote.isEmpty ? 'Chưa có' : task.completedNote,
                  multiLine: true,
                ),
              ],
            ),
          ),
          if (task.afterImageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection(
              icon: Icons.image_outlined,
              title: 'Ảnh sau xử lý',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  task.afterImageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 120,
                    color: const Color(0xFFF3F4F6),
                    alignment: Alignment.center,
                    child: SelectableText(
                      task.afterImageUrl,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (canSubmitCompletion) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EnvironmentTaskReportScreen(task: task),
                    ),
                  );

                  if (result == true && context.mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
                icon: const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Báo cáo đã dọn xong'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5EAC24),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5EAC24).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF5EAC24),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2D1D),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool multiLine = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
                color: Color(0xFF1F2D1D),
              ),
              maxLines: multiLine ? null : 1,
              overflow: multiLine ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) return 'Chưa có';
    return DateFormat('HH:mm dd/MM/yyyy').format(value);
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'ASSIGNED':
        return 'Đang chờ xử lý';
      case 'CLEANED_PENDING_CONFIRM':
        return 'Chờ admin duyệt';
      case 'RESOLVED':
        return 'Đã hoàn tất';
      default:
        return status;
    }
  }
}
