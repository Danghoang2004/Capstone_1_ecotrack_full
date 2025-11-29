package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PointTransactionRepository extends JpaRepository<PointTransaction, Long> {
    List<PointTransaction> findTop10ByUserIdOrderByCreatedAtDesc(Long userId);
    void deleteByUser(User user);

    // Đếm số lần user đã redeem một coupon cụ thể
    @Query("SELECT COUNT(t) FROM PointTransaction t WHERE t.user.id = :userId " +
           "AND t.actionType = 'VOUCHER' AND t.description LIKE CONCAT('%', :couponIdPattern, '%')")
    long countVoucherRedemptionsByUserAndCoupon(@Param("userId") Long userId,
                                                 @Param("couponIdPattern") String couponIdPattern);

    // Lấy tất cả transaction VOUCHER của user để debug
    @Query("SELECT t FROM PointTransaction t WHERE t.user.id = :userId " +
           "AND t.actionType = 'VOUCHER' ORDER BY t.createdAt DESC")
    List<PointTransaction> findAllVoucherTransactionsByUser(@Param("userId") Long userId);
}
