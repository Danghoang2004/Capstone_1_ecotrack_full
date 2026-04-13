package capstone_1.Ecotrack_backend.dto.request.environment;

import jakarta.validation.constraints.NotNull;

public class AssignEnvironmentTaskRequest {

    @NotNull(message = "reportId is required")
    private Long reportId;

    @NotNull(message = "teamLeadUserId is required")
    private Long teamLeadUserId;

    private String assignmentNote;
    private String plannedStartAt;
    private String plannedEndAt;
    private String dueAt;

    public Long getReportId() {
        return reportId;
    }

    public void setReportId(Long reportId) {
        this.reportId = reportId;
    }

    public Long getTeamLeadUserId() {
        return teamLeadUserId;
    }

    public void setTeamLeadUserId(Long teamLeadUserId) {
        this.teamLeadUserId = teamLeadUserId;
    }

    public String getAssignmentNote() {
        return assignmentNote;
    }

    public void setAssignmentNote(String assignmentNote) {
        this.assignmentNote = assignmentNote;
    }

    public String getDueAt() {
        return dueAt;
    }

    public void setDueAt(String dueAt) {
        this.dueAt = dueAt;
    }

    public String getPlannedStartAt() {
        return plannedStartAt;
    }

    public void setPlannedStartAt(String plannedStartAt) {
        this.plannedStartAt = plannedStartAt;
    }

    public String getPlannedEndAt() {
        return plannedEndAt;
    }

    public void setPlannedEndAt(String plannedEndAt) {
        this.plannedEndAt = plannedEndAt;
    }
}
