package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WasteReportRepository extends JpaRepository<WasteReport,Long> {
    Long countByUserId(Long userId);
    void deleteByUserId(Long userId);
    // Lấy báo cáo mới nhất của User để check thời gian (Cooldown)
    Optional<WasteReport> findTopByUserIdOrderByCreatedAtDesc(Long userId);

    // Đếm số lượng báo cáo của User kể từ một thời điểm cụ thể (dùng để check giới hạn ngày)
    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime timestamp);

    List<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId);
    List<WasteReport> findAllByOrderByCreatedAtDesc();
}
