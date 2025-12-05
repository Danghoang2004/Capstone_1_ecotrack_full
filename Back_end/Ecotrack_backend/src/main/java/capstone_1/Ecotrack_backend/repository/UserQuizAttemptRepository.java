package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.UserQuizAttempt;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

public interface UserQuizAttemptRepository extends JpaRepository<UserQuizAttempt, Long> {
    @Query("SELECT COUNT(DISTINCT a.quizId) FROM UserQuizAttempt a WHERE a.userId = :userId")
    int countDistinctQuizByUserId(Long userId);

    List<UserQuizAttempt> findByUserId(Long userId);
}
