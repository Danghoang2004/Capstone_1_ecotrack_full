package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.EnvironmentTeam;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface EnvironmentTeamRepository extends JpaRepository<EnvironmentTeam, Long> {
    boolean existsByTeamNameIgnoreCase(String teamName);

    List<EnvironmentTeam> findAllByOrderByCreatedAtDesc();
}
