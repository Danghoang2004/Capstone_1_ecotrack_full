package capstone_1.Ecotrack_backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BadgeRequest {
    private String badgeName;
    private String description;
    private String iconUrl;
    private String requirement;
    private Integer pointsRequired = 0;
}
