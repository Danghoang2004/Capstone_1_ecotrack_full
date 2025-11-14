package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class BadgeResponse {
    private Long badgeId;
    private String badgeName;
    private String iconUrl;
    private String description;
    private String requirement;
    private String awardedAt; // ISO string, optional
}
