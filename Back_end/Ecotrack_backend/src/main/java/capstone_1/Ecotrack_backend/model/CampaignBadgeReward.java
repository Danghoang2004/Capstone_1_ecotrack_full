package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "campaign_badge_rewards")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CampaignBadgeReward {

    @EmbeddedId
    private CampaignBadgeRewardId id;

    @ManyToOne
    @MapsId("campaignId")
    @JoinColumn(name = "campaign_id")
    private Campaign campaign;

    @ManyToOne
    @MapsId("badgeId")
    @JoinColumn(name = "badge_id")
    private Badge badge;
}
