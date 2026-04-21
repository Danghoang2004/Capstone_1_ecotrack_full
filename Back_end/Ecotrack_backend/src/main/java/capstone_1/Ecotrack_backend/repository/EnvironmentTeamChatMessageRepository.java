package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.EnvironmentTeamChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface EnvironmentTeamChatMessageRepository extends JpaRepository<EnvironmentTeamChatMessage, Long> {
    List<EnvironmentTeamChatMessage> findByTeamTeamIdOrderByMessageIdDesc(Long teamId, Pageable pageable);

    List<EnvironmentTeamChatMessage> findByTeamTeamIdAndMessageIdGreaterThanOrderByMessageIdAsc(Long teamId,
            Long afterMessageId,
            Pageable pageable);

    Optional<EnvironmentTeamChatMessage> findTopByTeamTeamIdOrderByMessageIdDesc(Long teamId);
}