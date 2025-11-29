package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ProfileResponse {

    private Long userId;

    // Basic user info
    private String fullName;
    private String avatarUrl;
    private String location;
    private String email;
    private String username;

    // Level info
    private String levelName;
    private String levelIcon;
    private Integer points;
    private Integer minPoints;
    private Integer maxPoints;

    // Statistics (cards)
    private Long reportCount;
    private Long groupCount;
    private Integer rank;

    // Badges
    private List<BadgeResponse> badges;

    // Recent activities
    private List<ActivityResponse> recentActivities;

    // Top 5 rankings
    private List<RankingUserResponse> topRankings;
}
