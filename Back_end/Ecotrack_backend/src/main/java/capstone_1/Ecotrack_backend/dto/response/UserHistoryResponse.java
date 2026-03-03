package capstone_1.Ecotrack_backend.dto.response;

import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Builder
public class UserHistoryResponse {

    private Long id;

    private String type; // POINT, REPORT, QUIZ

    private String title;

    private String description;

    private Integer points;

    private Integer score;

    private String status;

    private LocalDateTime createdAt;

}