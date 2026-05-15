package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.RecycleGuide;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RecycleGuideRepository extends JpaRepository<RecycleGuide, Long> {
}
