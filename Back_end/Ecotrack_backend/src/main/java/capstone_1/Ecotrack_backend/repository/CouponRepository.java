package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Coupon;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface CouponRepository extends JpaRepository<Coupon, Long> {
    List<Coupon> findByPartnerIdOrderByCreatedAtDesc(Long partnerId);
    Optional<Coupon> findByCode(String code);
    boolean existsByCode(String code);
}

