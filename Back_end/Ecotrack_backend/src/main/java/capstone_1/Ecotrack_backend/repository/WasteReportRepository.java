package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.dto.response.ClusterProjection; // Import thêm Interface Projection
import capstone_1.Ecotrack_backend.model.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query; // Import thêm annotation Query
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Repository
public interface WasteReportRepository extends JpaRepository<WasteReport, Long> {
    
    Long countByUserId(Long userId);
    
    void deleteByUserId(Long userId);
    
    // Lấy báo cáo mới nhất của User để check thời gian (Cooldown)
    Optional<WasteReport> findTopByUserIdOrderByCreatedAtDesc(Long userId);

    // Đếm số lượng báo cáo của User kể từ một thời điểm cụ thể (dùng để check giới hạn ngày)
    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime timestamp);

    List<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<WasteReport> findAllByOrderByCreatedAtDesc();

    // =========================================================================
    // API CHO ADMIN: Gom nhóm các điểm rác gần nhau (~110m) để hiển thị Heatmap
    // =========================================================================
    @Query(value = "SELECT " +
            "ROUND(gps_lat, 3) AS centerLat, " +
            "ROUND(gps_long, 3) AS centerLng, " +
            "COUNT(*) AS reportCount " +
            "FROM waste_reports " +
            "WHERE status IN ('PENDING', 'VERIFIED') " +
            "GROUP BY ROUND(gps_lat, 3), ROUND(gps_long, 3)", 
            nativeQuery = true)
    List<ClusterProjection> findWasteClusters();
}