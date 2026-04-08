package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.AiWasteClassificationHistory;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface AiWasteClassificationHistoryRepository extends JpaRepository<AiWasteClassificationHistory, Long> {
    List<AiWasteClassificationHistory> findByUserIdOrderByCreatedAtDesc(Long userId);
}
