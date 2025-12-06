// QuizOverviewItemDto.java
package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class QuizOverviewItemDto {
    private Long quizId;
    private String title;
    private String description;
    private boolean completed;
    private int percent;
    private int questionCount;
    private int timeSec;
    private int rewardPoints;

}
