package capstone_1.Ecotrack_backend.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import capstone_1.Ecotrack_backend.model.Coupon;

public interface CouponRepository extends JpaRepository<Coupon, Long> {

    @Query("SELECT COALESCE(SUM(c.discountValue * c.usedCount), 0) FROM Coupon c WHERE c.partner.partnerId = :partnerId")
    double sumRevenueByPartner(Long partnerId);

    @Query("SELECT COUNT(c) FROM Coupon c WHERE c.partner.partnerId = :partnerId AND c.isActive = true")
    long countActiveByPartner(Long partnerId);

    @Query("SELECT COALESCE(SUM(c.usedCount), 0) FROM Coupon c WHERE c.partner.partnerId = :partnerId")
    long sumUsageByPartner(Long partnerId);
}
