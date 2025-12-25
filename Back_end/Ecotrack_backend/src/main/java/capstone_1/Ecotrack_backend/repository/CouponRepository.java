package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Coupon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CouponRepository extends JpaRepository<Coupon, Long> {
    List<Coupon> findByPartnerIdOrderByCreatedAtDesc(Long partnerId);

    Optional<Coupon> findByCode(String code);

    boolean existsByCode(String code);

    @Query("""
            SELECT COALESCE(SUM(c.discountValue * c.usedCount), 0)
            FROM Coupon c
            WHERE c.partnerId = :partnerId
            """)
    double sumRevenueByPartner(Long partnerId);

    // Đếm số coupon đang active theo partnerId
    @Query("""
            SELECT COUNT(c)
            FROM Coupon c
            WHERE c.partnerId = :partnerId
              AND c.isActive = true
            """)
    long countActiveByPartner(Long partnerId);

    // Tổng lượt dùng coupon của partner
    @Query("""
            SELECT COALESCE(SUM(c.usedCount), 0)
            FROM Coupon c
            WHERE c.partnerId = :partnerId
            """)
    long sumUsageByPartner(Long partnerId);
}
