package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.RecycleSuggestion;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Collection;
import java.util.List;
import java.util.Optional;

public interface RecycleSuggestionRepository extends JpaRepository<RecycleSuggestion, Long> {

    @EntityGraph(attributePaths = { "steps" })
    List<RecycleSuggestion> findByWasteTypeKeyInAndIsActiveTrueOrderByWasteTypeKeyAscSuggestionIdAsc(
            Collection<String> wasteTypeKeys);

    @EntityGraph(attributePaths = { "steps" })
    Optional<RecycleSuggestion> findBySuggestionIdAndIsActiveTrue(Long suggestionId);
}
