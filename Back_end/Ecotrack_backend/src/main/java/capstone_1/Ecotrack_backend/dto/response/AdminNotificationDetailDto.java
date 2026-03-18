package capstone_1.Ecotrack_backend.dto.response;

import capstone_1.Ecotrack_backend.model.Notification;
import java.time.LocalDateTime;

public record AdminNotificationDetailDto(
        Long notificationId,
        Long userId,
        String title,
        String message,
        String type,
        String targetType,
        Long targetId,
        boolean isRead,
        LocalDateTime createdAt,
        String userName) {

    public static AdminNotificationDetailDto fromEntity(Notification notification, String userName) {
        return new AdminNotificationDetailDto(
                notification.getId(),
                notification.getUserId(),
                notification.getTitle(),
                notification.getMessage(),
                notification.getNotificationType().name(),
                notification.getTargetType(),
                notification.getTargetId(),
                notification.isRead(),
                notification.getCreatedAt(),
                userName);
    }
}
