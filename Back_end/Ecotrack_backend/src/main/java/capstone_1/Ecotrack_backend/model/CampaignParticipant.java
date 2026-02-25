package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "campaign_participants")
@AllArgsConstructor
@Builder

public class CampaignParticipant {

    @EmbeddedId
    private CampaignParticipantId id;

    @ManyToOne(fetch = FetchType.LAZY)

    @MapsId("campaignId")
    @JoinColumn(name = "campaign_id")
    private Campaign campaign;

    @ManyToOne(fetch = FetchType.LAZY)

    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt = LocalDateTime.now();

    public CampaignParticipant() {
    }

    public CampaignParticipant(Campaign campaign, User user) {
        this.campaign = campaign;
        this.user = user;

        // Lấy khóa chính từ Campaign và User để gán vào composite key
        this.id = new CampaignParticipantId(
                campaign.getCampaignId(), // id của campaign
                user.getId() // id của user (hoặc getUserId() nếu bạn đặt tên như vậy)
        );

        this.joinedAt = LocalDateTime.now();
    }

    public CampaignParticipantId getId() {
        return id;
    }

    public void setId(CampaignParticipantId id) {
        this.id = id;
    }

    public Campaign getCampaign() {
        return campaign;
    }

    public void setCampaign(Campaign campaign) {
        this.campaign = campaign;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(LocalDateTime joinedAt) {
        this.joinedAt = joinedAt;
    }

}
