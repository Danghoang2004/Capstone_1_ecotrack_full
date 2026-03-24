package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class BroadcastAllNotificationRequest {

    @NotBlank(message = "title is required")
    @Size(max = 200, message = "title must be <= 200 characters")
    private String title;

    @NotBlank(message = "message is required")
    private String message;

    @NotBlank(message = "notificationType is required")
    private String notificationType;

    private String targetType;
    private Long targetId;

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public String getNotificationType() {
        return notificationType;
    }

    public void setNotificationType(String notificationType) {
        this.notificationType = notificationType;
    }

    public String getTargetType() {
        return targetType;
    }

    public void setTargetType(String targetType) {
        this.targetType = targetType;
    }

    public Long getTargetId() {
        return targetId;
    }

    public void setTargetId(Long targetId) {
        this.targetId = targetId;
    }
}
