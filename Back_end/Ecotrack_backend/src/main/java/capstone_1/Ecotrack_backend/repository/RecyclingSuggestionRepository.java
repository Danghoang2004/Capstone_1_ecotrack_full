package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.RecyclingSuggestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecyclingSuggestionRepository extends JpaRepository<RecyclingSuggestion, Long> {
    List<RecyclingSuggestion> findByWasteCategory(String wasteCategory);
}