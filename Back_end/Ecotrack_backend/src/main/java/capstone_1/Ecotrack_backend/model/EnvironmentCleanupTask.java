package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "environment_cleanup_tasks")
public class EnvironmentCleanupTask {

    public enum TaskStatus {
        ASSIGNED,
        CLEANED_PENDING_CONFIRM,
        RESOLVED
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "task_id")
    private Long taskId;

    @Column(name = "report_id", nullable = false)
    private Long reportId;

    @Column(name = "team_lead_user_id", nullable = false)
    private Long teamLeadUserId;

    @Enumerated(EnumType.STRING)
    @Column(name = "status", nullable = false)
    private TaskStatus status = TaskStatus.ASSIGNED;

    @Column(name = "assignment_note", columnDefinition = "TEXT")
    private String assignmentNote;

    @Column(name = "planned_start_at")
    private LocalDateTime plannedStartAt;

    @Column(name = "planned_end_at")
    private LocalDateTime plannedEndAt;

    @Column(name = "due_at")
    private LocalDateTime dueAt;

    @Column(name = "assigned_at", nullable = false)
    private LocalDateTime assignedAt = LocalDateTime.now();

    @Column(name = "completed_note", columnDefinition = "TEXT")
    private String completedNote;

    @Column(name = "after_image_url", length = 500)
    private String afterImageUrl;

    @Column(name = "completed_gps_lat", precision = 10, scale = 6)
    private BigDecimal completedGpsLat;

    @Column(name = "completed_gps_long", precision = 10, scale = 6)
    private BigDecimal completedGpsLong;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;

    @Column(name = "resolved_by_admin_id")
    private Long resolvedByAdminId;

    @Column(name = "resolved_at")
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

    public Long getTeamLeadUserId() {
        return teamLeadUserId;
    }

    public void setTeamLeadUserId(Long teamLeadUserId) {
        this.teamLeadUserId = teamLeadUserId;
    }

    public TaskStatus getStatus() {
        return status;
    }

    public void setStatus(TaskStatus status) {
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

    public String getCompletedNote() {
        return completedNote;
    }

    public void setCompletedNote(String completedNote) {
        this.completedNote = completedNote;
    }

    public String getAfterImageUrl() {
        return afterImageUrl;
    }

    public void setAfterImageUrl(String afterImageUrl) {
        this.afterImageUrl = afterImageUrl;
    }

    public BigDecimal getCompletedGpsLat() {
        return completedGpsLat;
    }

    public void setCompletedGpsLat(BigDecimal completedGpsLat) {
        this.completedGpsLat = completedGpsLat;
    }

    public BigDecimal getCompletedGpsLong() {
        return completedGpsLong;
    }

    public void setCompletedGpsLong(BigDecimal completedGpsLong) {
        this.completedGpsLong = completedGpsLong;
    }

    public LocalDateTime getCompletedAt() {
        return completedAt;
    }

    public void setCompletedAt(LocalDateTime completedAt) {
        this.completedAt = completedAt;
    }

    public Long getResolvedByAdminId() {
        return resolvedByAdminId;
    }

    public void setResolvedByAdminId(Long resolvedByAdminId) {
        this.resolvedByAdminId = resolvedByAdminId;
    }

    public LocalDateTime getResolvedAt() {
        return resolvedAt;
    }

    public void setResolvedAt(LocalDateTime resolvedAt) {
        this.resolvedAt = resolvedAt;
    }
}
