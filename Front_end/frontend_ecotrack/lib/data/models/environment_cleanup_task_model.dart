class EnvironmentCleanupTask {
  final int taskId;
  final int reportId;
  final String reportTitle;
  final String reportCategory;
  final double? reportGpsLat;
  final double? reportGpsLong;
  final String reportStatus;
  final String status;
  final String assignmentNote;
  final DateTime? plannedStartAt;
  final DateTime? plannedEndAt;
  final DateTime? dueAt;
  final DateTime assignedAt;
  final String afterImageUrl;
  final String completedNote;
  final DateTime? completedAt;
  final DateTime? resolvedAt;
  final bool canSubmitCompletion;
  final int? teamLeadUserId;
  final String? teamLeadName;

  EnvironmentCleanupTask({
    required this.taskId,
    required this.reportId,
    required this.reportTitle,
    required this.reportCategory,
    required this.reportGpsLat,
    required this.reportGpsLong,
    required this.reportStatus,
    required this.status,
    required this.assignmentNote,
    required this.plannedStartAt,
    required this.plannedEndAt,
    required this.dueAt,
    required this.assignedAt,
    required this.afterImageUrl,
    required this.completedNote,
    required this.completedAt,
    required this.resolvedAt,
    required this.canSubmitCompletion,
    this.teamLeadUserId,
    this.teamLeadName,
  });

  factory EnvironmentCleanupTask.fromJson(Map<String, dynamic> json) {
    return EnvironmentCleanupTask(
      taskId: (json['taskId'] ?? 0) as int,
      reportId: (json['reportId'] ?? 0) as int,
      reportTitle: (json['reportTitle'] ?? '') as String,
      reportCategory: (json['reportCategory'] ?? '') as String,
      reportGpsLat: _parseDouble(json['reportGpsLat']),
      reportGpsLong: _parseDouble(json['reportGpsLong']),
      reportStatus: (json['reportStatus'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      assignmentNote: (json['assignmentNote'] ?? '') as String,
      plannedStartAt: _parseDate(json['plannedStartAt']),
      plannedEndAt: _parseDate(json['plannedEndAt']),
      dueAt: _parseDate(json['dueAt']),
      assignedAt: _parseDate(json['assignedAt']) ?? DateTime.now(),
      afterImageUrl: (json['afterImageUrl'] ?? '') as String,
      completedNote: (json['completedNote'] ?? '') as String,
      completedAt: _parseDate(json['completedAt']),
      resolvedAt: _parseDate(json['resolvedAt']),
      canSubmitCompletion: (json['canSubmitCompletion'] ?? false) as bool,
      teamLeadUserId: (json['teamLeadUserId'] ?? 0) as int?,
      teamLeadName: (json['teamLeadName'] ?? '') as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
