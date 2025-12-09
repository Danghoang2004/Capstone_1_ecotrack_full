package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.service.CampaignService;
import capstone_1.Ecotrack_backend.service.CampaignServiceImpl;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/campaigns")
@RequiredArgsConstructor
public class CampaignController {

    private final CampaignServiceImpl service;

    @GetMapping("/active")
    public List<CampaignResponse> getActiveCampaigns() {
        return service.getActiveCampaigns();
    }

    @GetMapping("/upcoming")
    public List<CampaignResponse> getUpcomingCampaigns() {
        return service.getUpcomingCampaigns();
    }
}
