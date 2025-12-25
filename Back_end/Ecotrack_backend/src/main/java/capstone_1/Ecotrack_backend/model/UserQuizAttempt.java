package capstone_1.Ecotrack_backend.model;


import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_quiz_attempts")
@Data
public class UserQuizAttempt {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "attempt_id")
    private Long id;

    private Long userId;
    private Long quizId;
    private Integer score;

    @Column(name = "completed_at")
    private LocalDateTime completedAt;
}

