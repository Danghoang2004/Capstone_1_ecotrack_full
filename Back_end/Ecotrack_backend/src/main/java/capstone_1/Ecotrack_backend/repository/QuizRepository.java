package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Quiz;
import org.springframework.data.jpa.repository.JpaRepository;

public interface QuizRepository extends JpaRepository<Quiz, Long> { }
