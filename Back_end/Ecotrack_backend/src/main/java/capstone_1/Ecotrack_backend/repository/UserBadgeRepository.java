package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.UserBadge;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UserBadgeRepository extends JpaRepository<UserBadge, Long> {

    @Query("select ub from UserBadge ub where ub.user.id = :userId")
    List<UserBadge> findByUserId(@Param("userId") Long userId);
}
