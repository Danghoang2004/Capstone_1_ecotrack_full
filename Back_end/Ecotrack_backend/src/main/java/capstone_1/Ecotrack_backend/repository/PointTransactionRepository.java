package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.PointTransaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface PointTransactionRepository extends JpaRepository<PointTransaction, Long> {

    // nếu entity PointTransaction có field "user" (kiểu User) thì nên viết như thế
    // này:
    List<PointTransaction> findTop10ByUser_IdOrderByCreatedAtDesc(Long userId);

    // ⭐ Tính tổng điểm theo userId
    @Query("""
            SELECT COALESCE(SUM(p.points), 0)
            FROM PointTransaction p
            WHERE p.user.id = :userId
            """)
    int sumPointsByUserId(@Param("userId") Long userId);

}
