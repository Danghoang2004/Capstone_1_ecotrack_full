package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.NotificationResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class NotificationBroadcastService {

    private final SimpMessagingTemplate messagingTemplate;

    public void sendNotificationToUser(Long userId, NotificationResponse notification) {
        String destination = "/user/" + userId + "/notifications";
        messagingTemplate.convertAndSendToUser(
                userId.toString(),
                "/notifications",
                notification
        );
    }

    public void broadcastToTopic(String topic, Object message) {
        messagingTemplate.convertAndSend("/topic/" + topic, message);
    }

    public void sendLeaderboardUpdate(Object leaderboardData) {
        broadcastToTopic("leaderboard", leaderboardData);
    }

    public void sendCampaignUpdate(Long campaignId, Object campaignData) {
        broadcastToTopic("campaign/" + campaignId, campaignData);
    }
}
