package capstone_1.Ecotrack_backend.service.environment;

import capstone_1.Ecotrack_backend.dto.request.environment.AssignEnvironmentTaskRequest;
import capstone_1.Ecotrack_backend.dto.request.environment.EnvironmentTaskCompletionRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentCleanupTaskResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamLeadResponse;
import capstone_1.Ecotrack_backend.exception.ForbiddenOperationException;
import capstone_1.Ecotrack_backend.exception.InvalidTaskStateException;
import capstone_1.Ecotrack_backend.exception.ResourceNotFoundException;
import capstone_1.Ecotrack_backend.model.EnvironmentCleanupTask;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.EnvironmentCleanupTaskRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

@Service
public class EnvironmentCleanupService {

    private static final double NEARBY_DUPLICATE_RADIUS_METERS = 100.0;

    private final EnvironmentCleanupTaskRepository taskRepository;
    private final WasteReportRepository wasteReportRepository;
    private final UserRepository userRepository;

    public EnvironmentCleanupService(EnvironmentCleanupTaskRepository taskRepository,
            WasteReportRepository wasteReportRepository,
            UserRepository userRepository) {
        this.taskRepository = taskRepository;
        this.wasteReportRepository = wasteReportRepository;
        this.userRepository = userRepository;
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
        return toResponse(saved, report);
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
        return taskRepository.findByTeamLeadUserIdOrderByAssignedAtDesc(currentUserId).stream()
                .map(this::toResponse)
                .toList();
    }

    public List<EnvironmentTeamLeadResponse> getEnvironmentTeamLeads() {
        return userRepository.findAll().stream()
                .filter(this::hasEnvironmentRole)
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
