package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.model.Campaign;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignService {
    Campaign createCampaign(CampaignRequestDto request);
    void joinCampaign(Long campaignId, Long userId);
}
