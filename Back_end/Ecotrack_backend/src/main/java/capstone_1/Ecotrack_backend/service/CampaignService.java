package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.model.Campaign;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CampaignService {
    Campaign createCampaign(CampaignRequestDto request);
    void joinCampaign(Long campaignId, Long userId);
    List<CampaignResponse> getAllCampaigns();
}
