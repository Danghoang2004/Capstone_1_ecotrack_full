package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.UserPoints;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserPointsRepository extends JpaRepository<UserPoints, Long> {
}
