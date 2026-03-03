package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WasteReportRepository extends JpaRepository<WasteReport, Long> {
    Long countByUserId(Long userId);

    void deleteByUserId(Long userId);

    Optional<WasteReport> findTopByUserIdOrderByCreatedAtDesc(Long userId);

    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime timestamp);

    List<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<WasteReport> findAllByOrderByCreatedAtDesc();

    Page<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId, Pageable pageable);
}
