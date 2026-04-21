package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.EnvironmentTeamChatReadState;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EnvironmentTeamChatReadStateRepository extends JpaRepository<EnvironmentTeamChatReadState, Long> {

    Optional<EnvironmentTeamChatReadState> findByTeamTeamIdAndUserId(Long teamId, Long userId);

    List<EnvironmentTeamChatReadState> findByTeamTeamIdAndUserIdIn(Long teamId, List<Long> userIds);
}
