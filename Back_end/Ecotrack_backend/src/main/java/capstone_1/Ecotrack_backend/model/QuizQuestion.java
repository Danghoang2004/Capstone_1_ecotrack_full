package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import lombok.Data;

@Entity
@Table(name = "quiz_questions")
@Data
public class QuizQuestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "question_id")          // ✅ map đúng cột
    private Long id;

    @ManyToOne
    @JoinColumn(name = "quiz_id")
    private Quiz quiz;

    @Column(name = "question_text")        // ✅ map đúng cột
    private String questionText;

    @Column(name = "option_a")             // ✅ map đúng cột
    private String optionA;

    @Column(name = "option_b")
    private String optionB;

    @Column(name = "option_c")
    private String optionC;

    @Column(name = "option_d")
    private String optionD;

    @Enumerated(EnumType.STRING)
    @Column(name = "correct_option")
    private Key correctOption;

    public enum Key { A, B, C, D }
}
