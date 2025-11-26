package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Leaderboard;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.Optional;

public interface LeaderboardRepository extends JpaRepository<Leaderboard, Long> {

    @Query("select l.rankPosition from Leaderboard l where l.user.id = :userId order by l.snapshotDate desc")
    Optional<Integer> findRankByUserId(@Param("userId") Long userId);
}
