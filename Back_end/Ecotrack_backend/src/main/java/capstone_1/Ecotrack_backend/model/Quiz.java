package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "quizzes")
@Data
public class Quiz {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "quiz_id")
    private Long id;

    private String title;

    @Column(name = "points_reward")
    private Integer pointsReward;

    @Enumerated(EnumType.STRING)
    private Status status;

    public enum Status { DRAFT, PUBLISHED }
}
