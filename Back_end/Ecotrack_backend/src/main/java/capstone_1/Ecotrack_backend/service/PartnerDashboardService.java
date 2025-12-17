package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.PartnerCampaignSummaryDto;
import capstone_1.Ecotrack_backend.dto.response.PartnerSponsorshipDashboardDto;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.CouponRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class PartnerDashboardService {

    private final CouponRepository couponRepository;
    private final CampaignRepository campaignRepository;

    public PartnerDashboardService(CouponRepository couponRepository,
            CampaignRepository campaignRepository) {
        this.couponRepository = couponRepository;
        this.campaignRepository = campaignRepository;
    }

    @Transactional(readOnly = true)
    public PartnerSponsorshipDashboardDto getSponsorshipDashboard(Long partnerId) {

        double totalRevenue = couponRepository.sumRevenueByPartner(partnerId);
        long activeCoupons = couponRepository.countActiveByPartner(partnerId);
        long couponUsage = couponRepository.sumUsageByPartner(partnerId);

        // Lấy trung bình rewardPoints (tạm coi là ROI)
        double avgRoi = campaignRepository.avgRoiByPartner(partnerId);

        List<PartnerCampaignSummaryDto> campaigns = campaignRepository.findCampaignSummariesByPartner(partnerId);

        PartnerSponsorshipDashboardDto dto = new PartnerSponsorshipDashboardDto();
        dto.setTotalRevenue(totalRevenue);
        dto.setActiveCoupons(activeCoupons);
        dto.setCouponUsage(couponUsage);
        dto.setAvgRoi(avgRoi);
        dto.setCampaigns(campaigns);

        return dto;
    }
}
