package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Level;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface LevelRepository extends JpaRepository<Level, Long> {

    // Tìm level thỏa mãn: min_points <= current_points <= max_points
    @Query("SELECT l FROM Level l WHERE :points >= l.minPoints AND :points < l.maxPoints")
    Optional<Level> findLevelByPoints(@Param("points") Integer points);

    // Trường hợp người dùng vượt quá số điểm của level cao nhất (nếu có)
    @Query(value = "SELECT * FROM levels ORDER BY max_points DESC LIMIT 1", nativeQuery = true)
    Level findMaxLevel();
}