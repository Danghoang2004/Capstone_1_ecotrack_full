package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.PartnerSponsorshipDashboardDto;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import org.springframework.stereotype.Service;

@Service
public class PartnerCurrentUserDashboardService {

    private final PartnerRepository partnerRepository;
    private final PartnerDashboardService dashboardService;

    public PartnerCurrentUserDashboardService(PartnerRepository partnerRepository,
            PartnerDashboardService dashboardService) {
        this.partnerRepository = partnerRepository;
        this.dashboardService = dashboardService;
    }

    public PartnerSponsorshipDashboardDto getDashboardForUser(Long userId) {
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Partner not found for userId = " + userId));

        return dashboardService.getSponsorshipDashboard(partner.getPartnerId());
    }
}
