package capstone_1.Ecotrack_backend.repository;


import capstone_1.Ecotrack_backend.model.UserVoucher;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface UserVoucherRepository extends JpaRepository<UserVoucher, Long> {
    List<UserVoucher> findByUserId(Long userId);
}

