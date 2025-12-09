package capstone_1.Ecotrack_backend.model;

import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.CampaignParticipantId;
import capstone_1.Ecotrack_backend.model.User;
import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "campaign_participants")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CampaignParticipant {

    @EmbeddedId
    private CampaignParticipantId id;

    @ManyToOne
    @MapsId("campaignId")
    @JoinColumn(name = "campaign_id")
    private Campaign campaign;

    @ManyToOne
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt = LocalDateTime.now();
}
