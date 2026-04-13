package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.EnvironmentTeamMember;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EnvironmentTeamMemberRepository extends JpaRepository<EnvironmentTeamMember, Long> {
        List<EnvironmentTeamMember> findByTeamTeamIdAndIsActiveTrue(Long teamId);

        List<EnvironmentTeamMember> findByUserIdAndIsActiveTrue(Long userId);

        List<EnvironmentTeamMember> findByIsActiveTrue();

        boolean existsByUserIdAndIsActiveTrue(Long userId);

        boolean existsByUserIdAndIsActiveTrueAndTeamTeamIdNot(Long userId, Long teamId);

        Optional<EnvironmentTeamMember> findByTeamTeamIdAndUserId(Long teamId, Long userId);

        Optional<EnvironmentTeamMember> findByTeamTeamIdAndUserIdAndIsActiveTrue(Long teamId, Long userId);

        boolean existsByTeamTeamIdAndUserIdAndIsActiveTrue(Long teamId, Long userId);

        List<EnvironmentTeamMember> findByTeamTeamIdAndRoleAndIsActiveTrue(Long teamId,
                        EnvironmentTeamMember.TeamRole role);

        boolean existsByUserIdAndRoleAndIsActiveTrueAndTeamIsActiveTrue(Long userId,
                        EnvironmentTeamMember.TeamRole role);

        List<EnvironmentTeamMember> findByTeamTeamIdInAndRoleAndIsActiveTrue(List<Long> teamIds,
                        EnvironmentTeamMember.TeamRole role);

        List<EnvironmentTeamMember> findByRoleAndIsActiveTrue(EnvironmentTeamMember.TeamRole role);
}
