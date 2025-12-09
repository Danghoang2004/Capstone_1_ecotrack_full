package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.Embeddable;
import lombok.AllArgsConstructor;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Embeddable
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CampaignBadgeRewardId implements java.io.Serializable {
    private Long campaignId;
    private Long badgeId;
}
