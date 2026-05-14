package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.model.UserBadgeId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface UserBadgeRepository extends JpaRepository<UserBadge, UserBadgeId> {

    @Query("select ub from UserBadge ub join fetch ub.badge where ub.user.id = :userId")
    List<UserBadge> findByUserId(@Param("userId") Long userId);

    void deleteByUser(User user);

    @Modifying
    @Transactional
    @Query("delete from UserBadge ub where ub.badge.badgeId = :badgeId")
    void deleteByBadgeId(@Param("badgeId") Long badgeId);

    @Query("select ub from UserBadge ub where ub.badge.badgeId = :badgeId")
    List<UserBadge> findByBadgeId(@Param("badgeId") Long badgeId);
}
