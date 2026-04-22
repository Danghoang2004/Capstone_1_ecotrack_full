package capstone_1.Ecotrack_backend.service.environment;

import capstone_1.Ecotrack_backend.dto.request.environment.AssignEnvironmentTaskRequest;
import capstone_1.Ecotrack_backend.dto.request.environment.EnvironmentTaskCompletionRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentCleanupTaskResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamLeadResponse;
import capstone_1.Ecotrack_backend.exception.ForbiddenOperationException;
import capstone_1.Ecotrack_backend.exception.InvalidTaskStateException;
import capstone_1.Ecotrack_backend.exception.ResourceNotFoundException;
import capstone_1.Ecotrack_backend.model.EnvironmentCleanupTask;
import capstone_1.Ecotrack_backend.model.EnvironmentTeamMember;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.EnvironmentCleanupTaskRepository;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamMemberRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import capstone_1.Ecotrack_backend.service.NotificationService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class EnvironmentCleanupService {

    private static final double NEARBY_DUPLICATE_RADIUS_METERS = 100.0;

    private final EnvironmentCleanupTaskRepository taskRepository;
    private final WasteReportRepository wasteReportRepository;
    private final UserRepository userRepository;
    private final EnvironmentTeamMemberRepository environmentTeamMemberRepository;
    private final NotificationService notificationService;

    public EnvironmentCleanupService(EnvironmentCleanupTaskRepository taskRepository,
            WasteReportRepository wasteReportRepository,
            UserRepository userRepository,
            EnvironmentTeamMemberRepository environmentTeamMemberRepository,
            NotificationService notificationService) {
        this.taskRepository = taskRepository;
        this.wasteReportRepository = wasteReportRepository;
        this.userRepository = userRepository;
        this.environmentTeamMemberRepository = environmentTeamMemberRepository;
        this.notificationService = notificationService;
    }

    @Transactional
    public EnvironmentCleanupTaskResponse assignTask(AssignEnvironmentTaskRequest request) {
        WasteReport report = wasteReportRepository.findById(request.getReportId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo rác."));

        if (report.getStatus() == WasteReport.Status.REJECTED || report.getStatus() == WasteReport.Status.CLEANED) {
            throw new InvalidTaskStateException("Không thể phân công xử lý cho báo cáo đã từ chối hoặc đã dọn.");
        }

        List<EnvironmentCleanupTask.TaskStatus> activeStatuses = List.of(
                EnvironmentCleanupTask.TaskStatus.ASSIGNED,
                EnvironmentCleanupTask.TaskStatus.CLEANED_PENDING_CONFIRM);

        List<EnvironmentCleanupTask> sameReportActiveTasks = taskRepository
                .findByReportIdAndStatusIn(request.getReportId(), activeStatuses);
        if (!sameReportActiveTasks.isEmpty()) {
            throw new InvalidTaskStateException("Báo cáo này đã có công việc môi trường đang xử lý/chờ duyệt.");
        }

        validateNearbyDuplicateTask(report, activeStatuses);

        boolean isActiveLead = environmentTeamMemberRepository
                .existsByUserIdAndRoleAndIsActiveTrueAndTeamIsActiveTrue(
                        request.getTeamLeadUserId(),
                        EnvironmentTeamMember.TeamRole.LEAD);

        if (!isActiveLead) {
            throw new InvalidTaskStateException("Người được phân công phải là team lead đang hoạt động.");
        }

        EnvironmentCleanupTask task = new EnvironmentCleanupTask();
        task.setReportId(request.getReportId());
        task.setTeamLeadUserId(request.getTeamLeadUserId());
        task.setAssignmentNote(request.getAssignmentNote());
        task.setAssignedAt(LocalDateTime.now());
        task.setStatus(EnvironmentCleanupTask.TaskStatus.ASSIGNED);
        LocalDateTime plannedStartAt = parseDateTime(request.getPlannedStartAt(), "plannedStartAt");
        LocalDateTime plannedEndAt = parseDateTime(
                request.getPlannedEndAt() != null ? request.getPlannedEndAt() : request.getDueAt(),
                "plannedEndAt");
        validatePlannedWindow(plannedStartAt, plannedEndAt);

        task.setPlannedStartAt(plannedStartAt);
        task.setPlannedEndAt(plannedEndAt);
        task.setDueAt(plannedEndAt);

        EnvironmentCleanupTask saved = taskRepository.save(task);
        notifyTeamMembersAboutNewTask(saved, report);
        return toResponse(saved, report);
    }

    private void notifyTeamMembersAboutNewTask(EnvironmentCleanupTask task, WasteReport report) {
        EnvironmentTeamMember leadMembership = environmentTeamMemberRepository
                .findByUserIdAndIsActiveTrue(task.getTeamLeadUserId()).stream()
                .filter(member -> member.getRole() == EnvironmentTeamMember.TeamRole.LEAD)
                .filter(member -> member.getTeam() != null && Boolean.TRUE.equals(member.getTeam().getIsActive()))
                .findFirst()
                .orElse(null);

        if (leadMembership == null || leadMembership.getTeam() == null) {
            return;
        }

        Long teamId = leadMembership.getTeam().getTeamId();
        String teamName = leadMembership.getTeam().getTeamName();
        List<Long> teamMemberUserIds = environmentTeamMemberRepository.findByTeamTeamIdAndIsActiveTrue(teamId)
                .stream()
                .map(EnvironmentTeamMember::getUserId)
                .distinct()
                .toList();

        if (teamMemberUserIds.isEmpty()) {
            return;
        }

        String reportTitle = report.getTitle() == null || report.getTitle().isBlank()
                ? ("Báo cáo #" + report.getReportId())
                : report.getTitle();

        for (Long memberUserId : teamMemberUserIds) {
            notificationService.createNotification(
                    memberUserId,
                    NotificationType.SYSTEM,
                    "Task mới cho đội " + teamName,
                    "Đội của bạn vừa được giao task mới: " + reportTitle,
                    "ENVIRONMENT_TASK",
                    task.getTaskId());
        }
    }

    private void validateNearbyDuplicateTask(WasteReport candidateReport,
            List<EnvironmentCleanupTask.TaskStatus> activeStatuses) {
        if (candidateReport.getGpsLat() == null || candidateReport.getGpsLong() == null) {
            return;
        }

        List<EnvironmentCleanupTask> activeTasks = new ArrayList<>(taskRepository.findByStatusIn(activeStatuses));

        for (EnvironmentCleanupTask task : activeTasks) {
            WasteReport existingReport = wasteReportRepository.findById(task.getReportId()).orElse(null);
            if (existingReport == null || existingReport.getGpsLat() == null || existingReport.getGpsLong() == null) {
                continue;
            }

            double distanceMeters = haversineMeters(
                    candidateReport.getGpsLat().doubleValue(),
                    candidateReport.getGpsLong().doubleValue(),
                    existingReport.getGpsLat().doubleValue(),
                    existingReport.getGpsLong().doubleValue());

            if (distanceMeters <= NEARBY_DUPLICATE_RADIUS_METERS) {
                throw new InvalidTaskStateException(
                        "Đã tồn tại công việc đang xử lý trong bán kính "
                                + (int) NEARBY_DUPLICATE_RADIUS_METERS
                                + "m (reportId=" + existingReport.getReportId() + ").");
            }
        }
    }

    private double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
        final double earthRadius = 6371000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);

        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                        * Math.sin(dLon / 2) * Math.sin(dLon / 2);

        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return earthRadius * c;
    }

    @Transactional
    public EnvironmentCleanupTaskResponse submitCleanupEvidence(Long taskId, Long currentUserId,
            EnvironmentTaskCompletionRequest request) {
        EnvironmentCleanupTask task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc môi trường."));

        if (!task.getTeamLeadUserId().equals(currentUserId)) {
            throw new ForbiddenOperationException("Bạn không có quyền cập nhật công việc này.");
        }

        if (task.getStatus() != EnvironmentCleanupTask.TaskStatus.ASSIGNED) {
            throw new InvalidTaskStateException("Công việc không ở trạng thái ASSIGNED để gửi bằng chứng.");
        }

        task.setAfterImageUrl(request.getAfterImageUrl());
        task.setCompletedGpsLat(request.getGpsLat());
        task.setCompletedGpsLong(request.getGpsLong());
        task.setCompletedNote(request.getCompletionNote());
        task.setCompletedAt(LocalDateTime.now());
        task.setStatus(EnvironmentCleanupTask.TaskStatus.CLEANED_PENDING_CONFIRM);

        EnvironmentCleanupTask saved = taskRepository.save(task);
        WasteReport report = wasteReportRepository.findById(saved.getReportId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo rác liên quan."));

        return toResponse(saved, report);
    }

    @Transactional
    public EnvironmentCleanupTaskResponse resolveTask(Long taskId, Long adminUserId) {
        EnvironmentCleanupTask task = taskRepository.findById(taskId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy công việc môi trường."));

        if (task.getStatus() != EnvironmentCleanupTask.TaskStatus.CLEANED_PENDING_CONFIRM) {
            throw new InvalidTaskStateException("Công việc chưa ở trạng thái chờ admin xác nhận.");
        }

        task.setStatus(EnvironmentCleanupTask.TaskStatus.RESOLVED);
        task.setResolvedByAdminId(adminUserId);
        task.setResolvedAt(LocalDateTime.now());
        EnvironmentCleanupTask saved = taskRepository.save(task);

        WasteReport report = wasteReportRepository.findById(saved.getReportId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo rác liên quan."));
        report.setStatus(WasteReport.Status.CLEANED);
        wasteReportRepository.save(report);

        return toResponse(saved, report);
    }

    public List<EnvironmentCleanupTaskResponse> getAllTasksForAdmin() {
        return taskRepository.findAllByOrderByAssignedAtDesc().stream()
                .map(this::toResponse)
                .toList();
    }

    public List<EnvironmentCleanupTaskResponse> getMyTasks(Long currentUserId) {
        List<Long> activeTeamIds = environmentTeamMemberRepository.findByUserIdAndIsActiveTrue(currentUserId).stream()
                .map(member -> member.getTeam().getTeamId())
                .distinct()
                .toList();

        if (activeTeamIds.isEmpty()) {
            return List.of();
        }

        Set<Long> leadUserIds = environmentTeamMemberRepository
                .findByTeamTeamIdInAndRoleAndIsActiveTrue(activeTeamIds, EnvironmentTeamMember.TeamRole.LEAD)
                .stream()
                .map(EnvironmentTeamMember::getUserId)
                .collect(Collectors.toSet());

        if (leadUserIds.isEmpty()) {
            return List.of();
        }

        return taskRepository.findByTeamLeadUserIdInOrderByAssignedAtDesc(new ArrayList<>(leadUserIds)).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<EnvironmentTeamLeadResponse> getEnvironmentTeamLeads() {
        List<Long> activeLeadIds = environmentTeamMemberRepository.findByRoleAndIsActiveTrue(
                EnvironmentTeamMember.TeamRole.LEAD)
                .stream()
                .filter(member -> member.getTeam() != null && Boolean.TRUE.equals(member.getTeam().getIsActive()))
                .map(EnvironmentTeamMember::getUserId)
                .distinct()
                .toList();

        if (activeLeadIds.isEmpty()) {
            return List.of();
        }

        return userRepository.findAllById(activeLeadIds).stream()
                .map(user -> new EnvironmentTeamLeadResponse(
                        user.getId(),
                        user.getUserProfile() != null && user.getUserProfile().getFullName() != null
                                ? user.getUserProfile().getFullName()
                                : user.getUsername(),
                        user.getUsername(),
                        user.getEmail()))
                .toList();
    }

    private boolean hasEnvironmentRole(User user) {
        return user.getRoles().stream().anyMatch(role -> "ROLE_ENVIRONMENT".equals(role.getName()));
    }

    private EnvironmentCleanupTaskResponse toResponse(EnvironmentCleanupTask task) {
        WasteReport report = wasteReportRepository.findById(task.getReportId())
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy báo cáo rác liên quan."));
        return toResponse(task, report);
    }

    private EnvironmentCleanupTaskResponse toResponse(EnvironmentCleanupTask task, WasteReport report) {
        EnvironmentCleanupTaskResponse response = new EnvironmentCleanupTaskResponse();
        response.setTaskId(task.getTaskId());
        response.setReportId(task.getReportId());
        response.setReportTitle(report.getTitle());
        response.setReportCategory(report.getCategory());
        response.setReportGpsLat(report.getGpsLat() == null ? null : report.getGpsLat().doubleValue());
        response.setReportGpsLong(report.getGpsLong() == null ? null : report.getGpsLong().doubleValue());
        response.setReportStatus(report.getStatus().name());
        response.setStatus(task.getStatus().name());
        response.setAssignmentNote(task.getAssignmentNote());
        response.setPlannedStartAt(task.getPlannedStartAt());
        response.setPlannedEndAt(task.getPlannedEndAt());
        response.setDueAt(task.getDueAt());
        response.setAssignedAt(task.getAssignedAt());
        response.setAfterImageUrl(task.getAfterImageUrl());
        response.setCompletedNote(task.getCompletedNote());
        response.setCompletedAt(task.getCompletedAt());
        response.setResolvedAt(task.getResolvedAt());
        response.setCanSubmitCompletion(EnvironmentCleanupTask.TaskStatus.ASSIGNED == task.getStatus());

        // Add team lead information
        response.setTeamLeadUserId(task.getTeamLeadUserId());
        User teamLeadUser = userRepository.findById(task.getTeamLeadUserId()).orElse(null);
        if (teamLeadUser != null && teamLeadUser.getUserProfile() != null &&
                teamLeadUser.getUserProfile().getFullName() != null &&
                !teamLeadUser.getUserProfile().getFullName().isBlank()) {
            response.setTeamLeadName(teamLeadUser.getUserProfile().getFullName());
        } else if (teamLeadUser != null) {
            response.setTeamLeadName(teamLeadUser.getUsername());
        } else {
            response.setTeamLeadName("N/A");
        }

        return response;
    }

    private LocalDateTime parseDateTime(String value, String fieldName) {
        if (value == null || value.isBlank()) {
            return null;
        }
        try {
            return LocalDateTime.parse(value);
        } catch (DateTimeParseException ex) {
            throw new InvalidTaskStateException(
                    "Định dạng " + fieldName
                            + " không hợp lệ. Dùng chuẩn ISO-8601, ví dụ: 2026-04-11T09:30:00");
        }
    }

    private void validatePlannedWindow(LocalDateTime startAt, LocalDateTime endAt) {
        if (startAt == null || endAt == null) {
            throw new InvalidTaskStateException("Vui lòng nhập đủ thời điểm bắt đầu và kết thúc.");
        }

        if (!endAt.isAfter(startAt)) {
            throw new InvalidTaskStateException("Thời điểm kết thúc phải sau thời điểm bắt đầu.");
        }
    }
}
