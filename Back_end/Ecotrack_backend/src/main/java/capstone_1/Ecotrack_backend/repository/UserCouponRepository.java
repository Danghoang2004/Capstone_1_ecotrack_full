package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.dto.response.UserCouponResponse;
import capstone_1.Ecotrack_backend.model.UserCoupon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UserCouponRepository extends JpaRepository<UserCoupon, Long> {

    @Query("""
                SELECT new capstone_1.Ecotrack_backend.dto.response.UserCouponResponse(
                    uc.userCouponId,
                    c.couponId,
                    c.title,
                    c.shortDescription,
                    p.companyName,
                    c.thumbnailUrl,
                    uc.status,
                    c.expiryDate,
                    uc.usedAt
                )
                FROM UserCoupon uc
                JOIN uc.coupon c
                JOIN c.partner p
                WHERE uc.user.id = :userId
                ORDER BY uc.createdAt DESC
            """)
    List<UserCouponResponse> findByUserId(@Param("userId") Long userId);
}