package capstone_1.Ecotrack_backend.model;
import jakarta.persistence.Embeddable;

import java.io.Serializable;
import java.util.Objects;

@Embeddable
public class UserBadgeId implements Serializable {

    private Long userId;
    private Long badgeId;

    public UserBadgeId() {}

    public UserBadgeId(Long userId, Long badgeId) {
        this.userId = userId;
        this.badgeId = badgeId;
    }

    // getters / setters
    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }
    public Long getBadgeId() { return badgeId; }
    public void setBadgeId(Long badgeId) { this.badgeId = badgeId; }

    // equals & hashCode
    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (!(o instanceof UserBadgeId)) return false;
        UserBadgeId that = (UserBadgeId) o;
        return Objects.equals(userId, that.userId) && Objects.equals(badgeId, that.badgeId);
    }

    @Override
    public int hashCode() {
        return Objects.hash(userId, badgeId);
    }
}
