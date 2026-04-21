package capstone_1.Ecotrack_backend.dto.response.environment;

import java.time.LocalDateTime;

public class EnvironmentCleanupTaskResponse {
    private Long taskId;
    private Long reportId;
    private String reportTitle;
    private String reportCategory;
    private Double reportGpsLat;
    private Double reportGpsLong;
    private String reportStatus;
    private String status;
    private String assignmentNote;
    private LocalDateTime plannedStartAt;
    private LocalDateTime plannedEndAt;
    private LocalDateTime dueAt;
    private LocalDateTime assignedAt;
    private String afterImageUrl;
    private String completedNote;
    private LocalDateTime completedAt;
    private LocalDateTime resolvedAt;
    private Boolean canSubmitCompletion;
    private Long teamLeadUserId;
    private String teamLeadName;

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

    public Double getReportGpsLat() {
        return reportGpsLat;
    }

    public void setReportGpsLat(Double reportGpsLat) {
        this.reportGpsLat = reportGpsLat;
    }

    public Double getReportGpsLong() {
        return reportGpsLong;
    }

    public void setReportGpsLong(Double reportGpsLong) {
        this.reportGpsLong = reportGpsLong;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getAssignmentNote() {
        return assignmentNote;
    }

    public void setAssignmentNote(String assignmentNote) {
        this.assignmentNote = assignmentNote;
    }

    public LocalDateTime getDueAt() {
        return dueAt;
    }

    public void setDueAt(LocalDateTime dueAt) {
        this.dueAt = dueAt;
    }

    public LocalDateTime getPlannedStartAt() {
        return plannedStartAt;
    }

    public void setPlannedStartAt(LocalDateTime plannedStartAt) {
        this.plannedStartAt = plannedStartAt;
    }

    public LocalDateTime getPlannedEndAt() {
        return plannedEndAt;
    }

    public void setPlannedEndAt(LocalDateTime plannedEndAt) {
        this.plannedEndAt = plannedEndAt;
    }

    public LocalDateTime getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(LocalDateTime assignedAt) {
        this.assignedAt = assignedAt;
    }

    public String getAfterImageUrl() {
        return afterImageUrl;
    }

    public void setAfterImageUrl(String afterImageUrl) {
        this.afterImageUrl = afterImageUrl;
    }

    public String getCompletedNote() {
        return completedNote;
    }

    public void setCompletedNote(String completedNote) {
        this.completedNote = completedNote;
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

    public Boolean getCanSubmitCompletion() {
        return canSubmitCompletion;
    }

    public void setCanSubmitCompletion(Boolean canSubmitCompletion) {
        this.canSubmitCompletion = canSubmitCompletion;
    }

    public Long getTeamLeadUserId() {
        return teamLeadUserId;
    }

    public void setTeamLeadUserId(Long teamLeadUserId) {
        this.teamLeadUserId = teamLeadUserId;
    }

    public String getTeamLeadName() {
        return teamLeadName;
    }

    public void setTeamLeadName(String teamLeadName) {
        this.teamLeadName = teamLeadName;
    }
}
