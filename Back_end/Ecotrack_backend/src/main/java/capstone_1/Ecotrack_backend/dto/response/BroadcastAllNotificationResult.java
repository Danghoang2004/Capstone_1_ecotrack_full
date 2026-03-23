package capstone_1.Ecotrack_backend.dto.response;

public class BroadcastAllNotificationResult {

    private int sentCount;
    private String notificationType;

    public BroadcastAllNotificationResult(int sentCount, String notificationType) {
        this.sentCount = sentCount;
        this.notificationType = notificationType;
    }

    public int getSentCount() {
        return sentCount;
    }

    public void setSentCount(int sentCount) {
        this.sentCount = sentCount;
    }

    public String getNotificationType() {
        return notificationType;
    }

    public void setNotificationType(String notificationType) {
        this.notificationType = notificationType;
    }
}
