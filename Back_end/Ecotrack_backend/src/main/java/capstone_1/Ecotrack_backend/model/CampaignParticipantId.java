package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Embeddable;
import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class CampaignParticipantId implements Serializable {

    @Column(name = "campaign_id")
    private Long campaignId;

    @Column(name = "user_id")
    private Long userId;

    public CampaignParticipantId() {
    }

    public CampaignParticipantId(Long campaignId, Long userId) {
        this.campaignId = campaignId;
        this.userId = userId;
    }

    public Long getCampaignId() {
        return campaignId;
    }

    public void setCampaignId(Long campaignId) {
        this.campaignId = campaignId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (!(o instanceof CampaignParticipantId that))
            return false;
        return Objects.equals(campaignId, that.campaignId)
                && Objects.equals(userId, that.userId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(campaignId, userId);
    }
}
