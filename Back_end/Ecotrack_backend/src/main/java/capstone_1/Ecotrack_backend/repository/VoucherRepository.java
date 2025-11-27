package capstone_1.Ecotrack_backend.repository;



import capstone_1.Ecotrack_backend.model.Voucher;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.time.LocalDate;
import java.util.List;

public interface VoucherRepository extends JpaRepository<Voucher, Long> {

    @Query("SELECT v FROM Voucher v WHERE v.quantity > 0 AND v.expiryDate >= :today")
    List<Voucher> findAvailable(@Param("today") LocalDate today);
}

    

