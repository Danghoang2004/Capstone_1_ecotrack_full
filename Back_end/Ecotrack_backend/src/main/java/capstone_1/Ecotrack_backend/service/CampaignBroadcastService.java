package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.CampaignDetailDTO;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CampaignBroadcastService {

    private final NotificationBroadcastService broadcastService;

    public void broadcastCampaignUpdate(Long campaignId, CampaignDetailDTO campaignData) {
        try {
            broadcastService.broadcastToTopic("campaign/" + campaignId, campaignData);
            System.out.println("✅ Broadcasted campaign update for campaign: " + campaignId);
        } catch (Exception e) {
            System.err.println("❌ Error broadcasting campaign update: " + e.getMessage());
        }
    }

    public void broadcastCampaignParticipantUpdate(Long campaignId, Object participantData) {
        try {
            broadcastService.broadcastToTopic("campaign/" + campaignId + "/participants", participantData);
            System.out.println("✅ Broadcasted campaign participant update for campaign: " + campaignId);
        } catch (Exception e) {
            System.err.println("❌ Error broadcasting participant update: " + e.getMessage());
        }
    }

    public void broadcastCampaignListUpdate() {
        try {
            broadcastService.broadcastToTopic("campaigns/updated", "Campaign list updated");
            System.out.println("✅ Broadcasted campaign list update");
        } catch (Exception e) {
            System.err.println("❌ Error broadcasting campaign list update: " + e.getMessage());
        }
    }
}
