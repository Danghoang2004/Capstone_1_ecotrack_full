package capstone_1.Ecotrack_backend.dto.response.environment;

import java.time.LocalDateTime;

public class EnvironmentTeamKpiTaskDetailResponse {
    private Long taskId;
    private Long reportId;
    private String reportTitle;
    private String reportCategory;
    private String reportStatus;
    private String taskStatus;
    private Long assigneeLeadId;
    private String assigneeLeadName;
    private LocalDateTime assignedAt;
    private LocalDateTime dueAt;
    private LocalDateTime completedAt;
    private LocalDateTime resolvedAt;

    public Long getTaskId() {
        return taskId;
    }

    public void setTaskId(Long taskId) {
        this.taskId = taskId;
    }

    public Long getReportId() {
        return reportId;
    }

    public void setReportId(Long reportId) {
        this.reportId = reportId;
    }

    public String getReportTitle() {
        return reportTitle;
    }

    public void setReportTitle(String reportTitle) {
        this.reportTitle = reportTitle;
    }

    public String getReportCategory() {
        return reportCategory;
    }

    public void setReportCategory(String reportCategory) {
        this.reportCategory = reportCategory;
    }

    public String getReportStatus() {
        return reportStatus;
    }

    public void setReportStatus(String reportStatus) {
        this.reportStatus = reportStatus;
    }

    public String getTaskStatus() {
        return taskStatus;
    }

    public void setTaskStatus(String taskStatus) {
        this.taskStatus = taskStatus;
    }

    public Long getAssigneeLeadId() {
        return assigneeLeadId;
    }

    public void setAssigneeLeadId(Long assigneeLeadId) {
        this.assigneeLeadId = assigneeLeadId;
    }

    public String getAssigneeLeadName() {
        return assigneeLeadName;
    }

    public void setAssigneeLeadName(String assigneeLeadName) {
        this.assigneeLeadName = assigneeLeadName;
    }

    public LocalDateTime getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(LocalDateTime assignedAt) {
        this.assignedAt = assignedAt;
    }

    public LocalDateTime getDueAt() {
        return dueAt;
    }

    public void setDueAt(LocalDateTime dueAt) {
        this.dueAt = dueAt;
    }

    public LocalDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}