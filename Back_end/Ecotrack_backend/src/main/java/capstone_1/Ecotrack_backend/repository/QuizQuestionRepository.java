package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.QuizQuestion;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.List;

public interface QuizQuestionRepository extends JpaRepository<QuizQuestion, Long> {
    List<QuizQuestion> findByQuiz_Id(Long quizId);

    long countByQuiz_Id(Long quizId);
}
