package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.UserQuizAttempt;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.*;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface UserQuizAttemptRepository
        extends JpaRepository<UserQuizAttempt, Long> {

    @Query("""
            SELECT COUNT(DISTINCT a.quizId)
            FROM UserQuizAttempt a
            WHERE a.userId = :userId
            """)
    int countDistinctQuizByUserId(
            @Param("userId") Long userId);

    List<UserQuizAttempt> findByUserId(Long userId);

    void deleteByQuizId(Long quizId);

    Page<UserQuizAttempt> findByUserIdOrderByCompletedAtDesc(
            Long userId,
            Pageable pageable);
}