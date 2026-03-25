package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.WasteReport;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

public interface WasteReportRepository extends JpaRepository<WasteReport, Long> {
    Long countByUserId(Long userId);

    void deleteByUserId(Long userId);

    // Lấy báo cáo mới nhất của User để check thời gian (Cooldown)
    Optional<WasteReport> findTopByUserIdOrderByCreatedAtDesc(Long userId);

    // Đếm số lượng báo cáo của User kể từ một thời điểm cụ thể (dùng để check giới
    // hạn ngày)
    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime timestamp);

    List<WasteReport> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<WasteReport> findAllByOrderByCreatedAtDesc();

    /**
     * Lấy báo cáo đã xác thực (VERIFIED) với tùy chọn lọc theo thời gian
     * 
     * @return Danh sách báo cáo VERIFIED
     */
    @Query("SELECT r FROM WasteReport r WHERE r.status = 'VERIFIED' " +
            "AND (:fromDate IS NULL OR r.createdAt >= :fromDate) " +
            "AND (:toDate IS NULL OR r.createdAt <= :toDate) " +
            "ORDER BY r.createdAt DESC")
    List<WasteReport> findVerifiedReports(
            @Param("fromDate") LocalDateTime fromDate,
            @Param("toDate") LocalDateTime toDate);

    /**
     * Lấy báo cáo VERIFIED trong vùng địa lý cụ thể với lọc thời gian
     */
    @Query("SELECT r FROM WasteReport r WHERE r.status = 'VERIFIED' " +
            "AND r.gpsLat >= :minLat AND r.gpsLat <= :maxLat " +
            "AND r.gpsLong >= :minLng AND r.gpsLong <= :maxLng " +
            "AND (:fromDate IS NULL OR r.createdAt >= :fromDate) " +
            "AND (:toDate IS NULL OR r.createdAt <= :toDate) " +
            "ORDER BY r.createdAt DESC")
    List<WasteReport> findVerifiedReportsInArea(
            @Param("minLat") Double minLat,
            @Param("maxLat") Double maxLat,
            @Param("minLng") Double minLng,
            @Param("maxLng") Double maxLng,
            @Param("fromDate") LocalDateTime fromDate,
            @Param("toDate") LocalDateTime toDate);
}
