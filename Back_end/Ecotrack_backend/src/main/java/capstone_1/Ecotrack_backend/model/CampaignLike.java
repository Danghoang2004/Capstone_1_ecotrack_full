package capstone_1.Ecotrack_backend.model;


import jakarta.persistence.*;
import lombok.*;

@Entity
@Table(name = "campaign_likes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class CampaignLike {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "campaign_like_id")
    private Long campaignLikeId;

    @ManyToOne
    @JoinColumn(name = "campaign_id")
    private Campaign campaign;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;
}
