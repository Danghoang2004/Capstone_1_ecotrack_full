// QuizSummaryDto.java
package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class QuizSummaryDto {
    private int completed;
    private int total;
    private int totalPoints;
    private List<QuizOverviewItemDto> items;
}
