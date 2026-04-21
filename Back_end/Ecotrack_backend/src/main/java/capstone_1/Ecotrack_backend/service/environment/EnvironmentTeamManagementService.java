package capstone_1.Ecotrack_backend.service.environment;

import capstone_1.Ecotrack_backend.dto.request.environment.CreateEnvironmentTeamRequest;
import capstone_1.Ecotrack_backend.dto.request.environment.UpdateEnvironmentTeamRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamKpiResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamKpiTaskDetailResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentMyTeamInfoResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamMemberResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamLeadResponse;
import capstone_1.Ecotrack_backend.exception.InvalidTaskStateException;
import capstone_1.Ecotrack_backend.exception.ResourceNotFoundException;
import capstone_1.Ecotrack_backend.model.EnvironmentCleanupTask;
import capstone_1.Ecotrack_backend.model.EnvironmentTeam;
import capstone_1.Ecotrack_backend.model.EnvironmentTeamMember;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.EnvironmentCleanupTaskRepository;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamMemberRepository;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class EnvironmentTeamManagementService {

    private final EnvironmentTeamRepository environmentTeamRepository;
    private final EnvironmentTeamMemberRepository environmentTeamMemberRepository;
    private final UserRepository userRepository;
    private final EnvironmentCleanupTaskRepository environmentCleanupTaskRepository;
    private final WasteReportRepository wasteReportRepository;

    public EnvironmentTeamManagementService(EnvironmentTeamRepository environmentTeamRepository,
            EnvironmentTeamMemberRepository environmentTeamMemberRepository,
            UserRepository userRepository,
            EnvironmentCleanupTaskRepository environmentCleanupTaskRepository,
            WasteReportRepository wasteReportRepository) {
        this.environmentTeamRepository = environmentTeamRepository;
        this.environmentTeamMemberRepository = environmentTeamMemberRepository;
        this.userRepository = userRepository;
        this.environmentCleanupTaskRepository = environmentCleanupTaskRepository;
        this.wasteReportRepository = wasteReportRepository;
    }

    @Transactional
    public EnvironmentTeamResponse createTeam(CreateEnvironmentTeamRequest request) {
        String normalizedName = normalizeTeamName(request.getTeamName());
        if (environmentTeamRepository.existsByTeamNameIgnoreCase(normalizedName)) {
            throw new InvalidTaskStateException("Tên đội đã tồn tại.");
        }

        User lead = getEnvironmentUserOrThrow(request.getLeadUserId());
        ensureUserNotInAnotherActiveTeam(lead.getId(), null);

        EnvironmentTeam team = new EnvironmentTeam();
        team.setTeamName(normalizedName);
        team.setDescription(request.getDescription());
        team.setIsActive(true);
        team.setCreatedAt(LocalDateTime.now());
        team.setUpdatedAt(LocalDateTime.now());
        EnvironmentTeam savedTeam = environmentTeamRepository.save(team);

        createOrActivateMembership(savedTeam, lead.getId(), EnvironmentTeamMember.TeamRole.LEAD);

        Set<Long> memberIds = new LinkedHashSet<>();
        if (request.getMemberUserIds() != null) {
            memberIds.addAll(request.getMemberUserIds());
        }
        memberIds.remove(lead.getId());

        for (Long memberId : memberIds) {
            getEnvironmentUserOrThrow(memberId);
            ensureUserNotInAnotherActiveTeam(memberId, null);
            createOrActivateMembership(savedTeam, memberId, EnvironmentTeamMember.TeamRole.MEMBER);
        }

        return mapTeam(savedTeam);
    }

    @Transactional
    public EnvironmentTeamResponse updateTeam(Long teamId, UpdateEnvironmentTeamRequest request) {
        EnvironmentTeam team = findTeamOrThrow(teamId);

        if (request.getTeamName() != null && !request.getTeamName().isBlank()) {
            String normalized = normalizeTeamName(request.getTeamName());
            if (!team.getTeamName().equalsIgnoreCase(normalized)
                    && environmentTeamRepository.existsByTeamNameIgnoreCase(normalized)) {
                throw new InvalidTaskStateException("Tên đội đã tồn tại.");
            }
            team.setTeamName(normalized);
        }

        if (request.getDescription() != null) {
            team.setDescription(request.getDescription());
        }

        if (request.getIsActive() != null) {
            team.setIsActive(request.getIsActive());
        }

        team.setUpdatedAt(LocalDateTime.now());
        EnvironmentTeam saved = environmentTeamRepository.save(team);
        return mapTeam(saved);
    }

    @Transactional
    public EnvironmentTeamResponse setTeamLead(Long teamId, Long userId) {
        EnvironmentTeam team = findTeamOrThrow(teamId);
        getEnvironmentUserOrThrow(userId);
        ensureUserNotInAnotherActiveTeam(userId, teamId);

        List<EnvironmentTeamMember> currentLeads = environmentTeamMemberRepository
                .findByTeamTeamIdAndRoleAndIsActiveTrue(teamId, EnvironmentTeamMember.TeamRole.LEAD);

        for (EnvironmentTeamMember currentLead : currentLeads) {
            if (!currentLead.getUserId().equals(userId)) {
                currentLead.setRole(EnvironmentTeamMember.TeamRole.MEMBER);
                environmentTeamMemberRepository.save(currentLead);
            }
        }

        createOrActivateMembership(team, userId, EnvironmentTeamMember.TeamRole.LEAD);

        team.setUpdatedAt(LocalDateTime.now());
        environmentTeamRepository.save(team);

        return mapTeam(team);
    }

    @Transactional
    public EnvironmentTeamResponse addMember(Long teamId, Long userId) {
        EnvironmentTeam team = findTeamOrThrow(teamId);
        getEnvironmentUserOrThrow(userId);
        ensureUserNotInAnotherActiveTeam(userId, teamId);

        if (environmentTeamMemberRepository.existsByTeamTeamIdAndUserIdAndIsActiveTrue(teamId, userId)) {
            throw new InvalidTaskStateException("Người dùng đã là thành viên của đội.");
        }

        createOrActivateMembership(team, userId, EnvironmentTeamMember.TeamRole.MEMBER);

        team.setUpdatedAt(LocalDateTime.now());
        environmentTeamRepository.save(team);

        return mapTeam(team);
    }

    @Transactional
    public EnvironmentTeamResponse removeMember(Long teamId, Long userId) {
        EnvironmentTeam team = findTeamOrThrow(teamId);

        EnvironmentTeamMember member = environmentTeamMemberRepository
                .findByTeamTeamIdAndUserIdAndIsActiveTrue(teamId, userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy thành viên trong đội."));

        if (member.getRole() == EnvironmentTeamMember.TeamRole.LEAD) {
            throw new InvalidTaskStateException("Không thể xoá team lead. Hãy chỉ định lead mới trước.");
        }

        member.setIsActive(false);
        member.setRemovedAt(LocalDateTime.now());
        environmentTeamMemberRepository.save(member);

        team.setUpdatedAt(LocalDateTime.now());
        environmentTeamRepository.save(team);

        return mapTeam(team);
    }

    @Transactional(readOnly = true)
    public List<EnvironmentTeamResponse> getAllTeams() {
        return environmentTeamRepository.findAllByOrderByCreatedAtDesc().stream()
                .map(this::mapTeam)
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EnvironmentTeamKpiResponse> getTeamKpis(String fromAt, String toAt) {
        LocalDateTime from = parseDateTimeOrDefault(fromAt, LocalDateTime.now().minusDays(30));
        LocalDateTime to = parseDateTimeOrDefault(toAt, LocalDateTime.now());

        if (to.isBefore(from)) {
            throw new InvalidTaskStateException("Khoảng thời gian KPI không hợp lệ.");
        }

        List<EnvironmentTeam> teams = environmentTeamRepository.findAllByOrderByCreatedAtDesc();
        List<EnvironmentTeamKpiResponse> responses = new ArrayList<>();

        for (EnvironmentTeam team : teams) {
            List<EnvironmentTeamMember> leads = environmentTeamMemberRepository
                    .findByTeamTeamIdAndRoleAndIsActiveTrue(team.getTeamId(), EnvironmentTeamMember.TeamRole.LEAD);

            List<Long> leadUserIds = leads.stream().map(EnvironmentTeamMember::getUserId).distinct().toList();
            List<EnvironmentCleanupTask> tasks = leadUserIds.isEmpty()
                    ? Collections.emptyList()
                    : environmentCleanupTaskRepository.findByTeamLeadUserIdInAndAssignedAtBetween(leadUserIds, from,
                            to);

            int totalAssigned = tasks.size();
            int totalCompletedPending = (int) tasks.stream()
                    .filter(task -> task.getStatus() == EnvironmentCleanupTask.TaskStatus.CLEANED_PENDING_CONFIRM)
                    .count();
            int totalResolved = (int) tasks.stream()
                    .filter(task -> task.getStatus() == EnvironmentCleanupTask.TaskStatus.RESOLVED)
                    .count();

            double completionRate = totalAssigned == 0 ? 0.0
                    : Math.round((totalResolved * 10000.0) / totalAssigned) / 100.0;

            List<Long> resolutionMinutes = tasks.stream()
                    .filter(task -> task.getStatus() == EnvironmentCleanupTask.TaskStatus.RESOLVED)
                    .filter(task -> task.getResolvedAt() != null && task.getAssignedAt() != null)
                    .map(task -> Duration.between(task.getAssignedAt(), task.getResolvedAt()).toMinutes())
                    .toList();

            Long avgResolutionMinutes = null;
            if (!resolutionMinutes.isEmpty()) {
                avgResolutionMinutes = Math.round(
                        resolutionMinutes.stream().collect(Collectors.averagingLong(Long::longValue)));
            }

            EnvironmentTeamKpiResponse response = new EnvironmentTeamKpiResponse();
            response.setTeamId(team.getTeamId());
            response.setTeamName(team.getTeamName());
            response.setFromAt(from.toString());
            response.setToAt(to.toString());
            response.setTotalAssigned(totalAssigned);
            response.setTotalCompletedPending(totalCompletedPending);
            response.setTotalResolved(totalResolved);
            response.setCompletionRate(completionRate);
            response.setAvgResolutionMinutes(avgResolutionMinutes);

            responses.add(response);
        }

        return responses;
    }

    @Transactional(readOnly = true)
    public List<EnvironmentTeamLeadResponse> getEnvironmentUsers() {
        Set<Long> activeTeamUserIds = environmentTeamMemberRepository.findByIsActiveTrue().stream()
                .map(EnvironmentTeamMember::getUserId)
                .collect(Collectors.toSet());

        return userRepository.findAll().stream()
                .filter(this::hasEnvironmentRole)
                .filter(user -> !activeTeamUserIds.contains(user.getId()))
                .map(user -> new EnvironmentTeamLeadResponse(
                        user.getId(),
                        user.getUserProfile() != null && user.getUserProfile().getFullName() != null
                                ? user.getUserProfile().getFullName()
                                : user.getUsername(),
                        user.getUsername(),
                        user.getEmail()))
                .toList();
    }

    @Transactional(readOnly = true)
    public List<EnvironmentTeamKpiTaskDetailResponse> getTeamKpiTaskDetails(Long teamId, String fromAt, String toAt) {
        EnvironmentTeam team = findTeamOrThrow(teamId);
        boolean hasFrom = fromAt != null && !fromAt.isBlank();
        boolean hasTo = toAt != null && !toAt.isBlank();

        LocalDateTime from = null;
        LocalDateTime to = null;
        if (hasFrom || hasTo) {
            from = parseDateTimeOrDefault(fromAt, LocalDateTime.now().minusDays(30));
            to = parseDateTimeOrDefault(toAt, LocalDateTime.now());

            if (to.isBefore(from)) {
                throw new InvalidTaskStateException("Khoảng thời gian KPI không hợp lệ.");
            }
        }

        List<EnvironmentTeamMember> leads = environmentTeamMemberRepository
                .findByTeamTeamIdAndRoleAndIsActiveTrue(team.getTeamId(), EnvironmentTeamMember.TeamRole.LEAD);

        List<Long> leadUserIds = leads.stream().map(EnvironmentTeamMember::getUserId).distinct().toList();
        if (leadUserIds.isEmpty()) {
            return List.of();
        }

        List<EnvironmentCleanupTask> tasks;
        if (from != null && to != null) {
            tasks = environmentCleanupTaskRepository
                    .findByTeamLeadUserIdInAndAssignedAtBetween(leadUserIds, from, to);
        } else {
            tasks = environmentCleanupTaskRepository
                    .findByTeamLeadUserIdInOrderByAssignedAtDesc(leadUserIds);
        }

        Map<Long, WasteReport> reportById = wasteReportRepository
                .findAllById(tasks.stream().map(EnvironmentCleanupTask::getReportId).distinct().toList())
                .stream()
                .collect(Collectors.toMap(WasteReport::getReportId, report -> report));

        Map<Long, User> leadUserById = userRepository.findAllById(leadUserIds).stream()
                .collect(Collectors.toMap(User::getId, user -> user));

        return tasks.stream()
                .sorted((a, b) -> b.getAssignedAt().compareTo(a.getAssignedAt()))
                .map(task -> {
                    WasteReport report = reportById.get(task.getReportId());
                    User leadUser = leadUserById.get(task.getTeamLeadUserId());

                    String leadName = leadUser != null && leadUser.getUserProfile() != null
                            && leadUser.getUserProfile().getFullName() != null
                                    ? leadUser.getUserProfile().getFullName()
                                    : (leadUser != null ? leadUser.getUsername() : "Không xác định");

                    EnvironmentTeamKpiTaskDetailResponse response = new EnvironmentTeamKpiTaskDetailResponse();
                    response.setTaskId(task.getTaskId());
                    response.setReportId(task.getReportId());
                    response.setReportTitle(report != null && report.getTitle() != null
                            ? report.getTitle()
                            : ("Báo cáo #" + task.getReportId()));
                    response.setReportCategory(report == null ? null : report.getCategory());
                    response.setReportStatus(
                            report == null || report.getStatus() == null ? null : report.getStatus().name());
                    response.setTaskStatus(task.getStatus().name());
                    response.setAssigneeLeadId(task.getTeamLeadUserId());
                    response.setAssigneeLeadName(leadName);
                    response.setAssignedAt(task.getAssignedAt());
                    response.setDueAt(task.getDueAt());
                    response.setCompletedAt(task.getCompletedAt());
                    response.setResolvedAt(task.getResolvedAt());
                    return response;
                })
                .toList();
    }

    @Transactional(readOnly = true)
    public EnvironmentMyTeamInfoResponse getMyTeamInfo(Long currentUserId) {
        EnvironmentTeamMember myMembership = environmentTeamMemberRepository
                .findByUserIdAndIsActiveTrue(currentUserId).stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thuộc đội môi trường nào."));

        EnvironmentTeam team = myMembership.getTeam();
        if (team == null || !Boolean.TRUE.equals(team.getIsActive())) {
            throw new ResourceNotFoundException("Đội môi trường không tồn tại hoặc đã ngừng hoạt động.");
        }

        List<EnvironmentTeamMember> activeMembers = environmentTeamMemberRepository
                .findByTeamTeamIdAndIsActiveTrue(team.getTeamId());

        EnvironmentTeamMember leadMember = activeMembers.stream()
                .filter(member -> member.getRole() == EnvironmentTeamMember.TeamRole.LEAD)
                .findFirst()
                .orElse(null);

        String leadFullName = "Chưa xác định";
        Long leadUserId = null;
        if (leadMember != null) {
            leadUserId = leadMember.getUserId();
            User leadUser = userRepository.findById(leadMember.getUserId()).orElse(null);
            if (leadUser != null) {
                leadFullName = leadUser.getUserProfile() != null && leadUser.getUserProfile().getFullName() != null
                        ? leadUser.getUserProfile().getFullName()
                        : leadUser.getUsername();
            }
        }

        EnvironmentMyTeamInfoResponse response = new EnvironmentMyTeamInfoResponse();
        response.setTeamId(team.getTeamId());
        response.setTeamName(team.getTeamName());
        response.setTeamDescription(team.getDescription());
        response.setMyRoleInTeam(myMembership.getRole().name());
        response.setLeadUserId(leadUserId);
        response.setLeadFullName(leadFullName);
        response.setMemberCount(activeMembers.size());
        return response;
    }

    private EnvironmentTeamResponse mapTeam(EnvironmentTeam team) {
        List<EnvironmentTeamMember> activeMembers = environmentTeamMemberRepository
                .findByTeamTeamIdAndIsActiveTrue(team.getTeamId());

        List<Long> userIds = activeMembers.stream().map(EnvironmentTeamMember::getUserId).distinct().toList();
        Map<Long, User> usersById = new HashMap<>();
        if (!userIds.isEmpty()) {
            usersById = userRepository.findAllById(userIds).stream()
                    .collect(Collectors.toMap(User::getId, user -> user));
        }

        EnvironmentTeamMemberResponse lead = null;
        List<EnvironmentTeamMemberResponse> members = new ArrayList<>();

        for (EnvironmentTeamMember member : activeMembers) {
            User user = usersById.get(member.getUserId());
            if (user == null) {
                continue;
            }

            EnvironmentTeamMemberResponse item = mapMember(user, member.getRole());
            if (member.getRole() == EnvironmentTeamMember.TeamRole.LEAD) {
                lead = item;
            } else {
                members.add(item);
            }
        }

        EnvironmentTeamResponse response = new EnvironmentTeamResponse();
        response.setTeamId(team.getTeamId());
        response.setTeamName(team.getTeamName());
        response.setDescription(team.getDescription());
        response.setIsActive(team.getIsActive());
        response.setCreatedAt(team.getCreatedAt());
        response.setUpdatedAt(team.getUpdatedAt());
        response.setLead(lead);
        response.setMembers(members);
        return response;
    }

    private EnvironmentTeamMemberResponse mapMember(User user, EnvironmentTeamMember.TeamRole role) {
        EnvironmentTeamMemberResponse response = new EnvironmentTeamMemberResponse();
        response.setUserId(user.getId());
        response.setUsername(user.getUsername());
        response.setEmail(user.getEmail());
        response.setRole(role.name());

        String fullName = user.getUserProfile() != null && user.getUserProfile().getFullName() != null
                ? user.getUserProfile().getFullName()
                : user.getUsername();
        response.setFullName(fullName);
        return response;
    }

    private EnvironmentTeam findTeamOrThrow(Long teamId) {
        return environmentTeamRepository.findById(teamId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy đội môi trường."));
    }

    private User getEnvironmentUserOrThrow(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ResourceNotFoundException("Không tìm thấy người dùng môi trường."));

        if (!hasEnvironmentRole(user)) {
            throw new InvalidTaskStateException("Người dùng không thuộc vai trò môi trường.");
        }

        return user;
    }

    private boolean hasEnvironmentRole(User user) {
        return user.getRoles().stream().anyMatch(role -> "ROLE_ENVIRONMENT".equals(role.getName()));
    }

    private void createOrActivateMembership(EnvironmentTeam team, Long userId, EnvironmentTeamMember.TeamRole role) {
        EnvironmentTeamMember membership = environmentTeamMemberRepository
                .findByTeamTeamIdAndUserId(team.getTeamId(), userId)
                .orElse(null);

        if (membership == null) {
            membership = new EnvironmentTeamMember();
            membership.setTeam(team);
            membership.setUserId(userId);
            membership.setJoinedAt(LocalDateTime.now());
        } else if (membership.getJoinedAt() == null) {
            membership.setJoinedAt(LocalDateTime.now());
        }

        membership.setRole(role);
        membership.setIsActive(true);
        membership.setRemovedAt(null);
        environmentTeamMemberRepository.save(membership);
    }

    private void ensureUserNotInAnotherActiveTeam(Long userId, Long currentTeamId) {
        boolean isInAnotherActiveTeam = currentTeamId == null
                ? environmentTeamMemberRepository.existsByUserIdAndIsActiveTrue(userId)
                : environmentTeamMemberRepository.existsByUserIdAndIsActiveTrueAndTeamTeamIdNot(userId,
                        currentTeamId);

        if (isInAnotherActiveTeam) {
            throw new InvalidTaskStateException("Người dùng đã thuộc một đội môi trường khác.");
        }
    }

    private String normalizeTeamName(String teamName) {
        if (teamName == null || teamName.isBlank()) {
            throw new InvalidTaskStateException("Tên đội không được để trống.");
        }
        return teamName.trim();
    }

    private LocalDateTime parseDateTimeOrDefault(String raw, LocalDateTime defaultValue) {
        if (raw == null || raw.isBlank()) {
            return defaultValue;
        }

        try {
            return LocalDateTime.parse(raw);
        } catch (Exception ex) {
            throw new InvalidTaskStateException(
                    "Định dạng thời gian không hợp lệ. Dùng ISO-8601, ví dụ 2026-04-13T09:00:00");
        }
    }
}
