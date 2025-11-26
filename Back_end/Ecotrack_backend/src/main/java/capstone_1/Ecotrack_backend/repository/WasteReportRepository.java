package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;

public interface WasteReportRepository extends JpaRepository<WasteReport,Long> {
    Long countByUserId(Long userId);
}
