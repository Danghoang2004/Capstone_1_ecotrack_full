package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "user_broadcast_read_state")
public class AdminBroadcastReadState {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "last_read_master_notification_id", nullable = false)
    private Long lastReadNotificationId = 0L;

    @Column(name = "updated_at", nullable = false)
    private LocalDateTime updatedAt;

    @PrePersist
    @PreUpdate
    public void preSave() {
        updatedAt = LocalDateTime.now();
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getLastReadNotificationId() {
        return lastReadNotificationId;
    }

    public void setLastReadNotificationId(Long lastReadNotificationId) {
        this.lastReadNotificationId = lastReadNotificationId;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }
}
