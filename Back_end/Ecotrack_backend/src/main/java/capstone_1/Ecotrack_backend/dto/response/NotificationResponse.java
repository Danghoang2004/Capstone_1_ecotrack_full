package capstone_1.Ecotrack_backend.dto.response;

import capstone_1.Ecotrack_backend.model.Notification;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class NotificationResponse {
    private Long id;
    private String title;
    private String message;
    private String type;      // CAMPAIGN / REWARD / ...
    private boolean read;
    private String createdAt; // ISO string

    public static NotificationResponse fromEntity(Notification n) {
        return new NotificationResponse(
                n.getId(),
                n.getTitle(),
                n.getMessage(),
                n.getNotificationType().name(),
                n.isRead(),
                n.getCreatedAt() == null ? null : n.getCreatedAt().toString()
        );
    }
}
