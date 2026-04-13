package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.EnvironmentCleanupTask;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface EnvironmentCleanupTaskRepository extends JpaRepository<EnvironmentCleanupTask, Long> {
        List<EnvironmentCleanupTask> findByTeamLeadUserIdOrderByAssignedAtDesc(Long teamLeadUserId);

        Optional<EnvironmentCleanupTask> findTopByReportIdOrderByAssignedAtDesc(Long reportId);

        List<EnvironmentCleanupTask> findByReportIdAndStatusIn(Long reportId,
                        List<EnvironmentCleanupTask.TaskStatus> statuses);

        List<EnvironmentCleanupTask> findByStatusIn(List<EnvironmentCleanupTask.TaskStatus> statuses);

        List<EnvironmentCleanupTask> findAllByOrderByAssignedAtDesc();

        List<EnvironmentCleanupTask> findByTeamLeadUserIdInAndAssignedAtBetween(List<Long> teamLeadUserIds,
                        LocalDateTime from,
                        LocalDateTime to);

        List<EnvironmentCleanupTask> findByTeamLeadUserIdInOrderByAssignedAtDesc(List<Long> teamLeadUserIds);
}
