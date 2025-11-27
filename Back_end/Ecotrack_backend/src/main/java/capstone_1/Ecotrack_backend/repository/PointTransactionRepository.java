package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface PointTransactionRepository extends JpaRepository<PointTransaction, Long> {
    List<PointTransaction> findTop10ByUserIdOrderByCreatedAtDesc(Long userId);
    void deleteByUser(User user);
}
