package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.QuizQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

public interface QuizQuestionRepository extends JpaRepository<QuizQuestion, Long> {
    List<QuizQuestion> findByQuiz_Id(Long quizId);

    long countByQuiz_Id(Long quizId);

    @Modifying
    @Transactional
    void deleteByQuiz_Id(Long quizId);
}
