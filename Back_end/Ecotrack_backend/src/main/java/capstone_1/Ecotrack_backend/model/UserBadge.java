package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "user_badges")
public class UserBadge {

    @EmbeddedId
    private UserBadgeId id;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("userId")
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @MapsId("badgeId")
    @JoinColumn(name = "badge_id")
    private Badge badge;

    @Column(name = "awarded_at")
    private LocalDateTime awardedAt = LocalDateTime.now();

    public UserBadge() {}

    public UserBadge(User user, Badge badge) {
        this.user = user;
        this.badge = badge;
        this.id = new UserBadgeId(user.getId(), badge.getBadgeId());
    }

    // getters / setters
    public UserBadgeId getId() { return id; }
    public void setId(UserBadgeId id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Badge getBadge() { return badge; }
    public void setBadge(Badge badge) { this.badge = badge; }

    public LocalDateTime getAwardedAt() { return awardedAt; }
    public void setAwardedAt(LocalDateTime awardedAt) { this.awardedAt = awardedAt; }
}
