package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class CampaignResponse {
    private Long id;
    private String title;
    private String description;
    private String imageUrl;
    private String dateTime;
    private Integer participants;
    private String location;
    private Integer rewardPoints;
    private Integer daysRemaining;
    private boolean joined;
}
