package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Badge;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface BadgeRepository extends JpaRepository<Badge, Long> {
    List<Badge> findAllByOrderByBadgeIdAsc();
}
