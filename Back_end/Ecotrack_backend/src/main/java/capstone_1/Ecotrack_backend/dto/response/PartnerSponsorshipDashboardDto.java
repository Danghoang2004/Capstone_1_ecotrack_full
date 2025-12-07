package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;

public class PartnerSponsorshipDashboardDto {

    private double totalRevenue;
    private long activeCoupons;
    private long couponUsage;
    private double avgRoi; // dùng double cho phù hợp với query AVG
    private List<PartnerCampaignSummaryDto> campaigns;

    public PartnerSponsorshipDashboardDto() {
    }

    public PartnerSponsorshipDashboardDto(double totalRevenue,
            long activeCoupons,
            long couponUsage,
            double avgRoi,
            List<PartnerCampaignSummaryDto> campaigns) {
        this.totalRevenue = totalRevenue;
        this.activeCoupons = activeCoupons;
        this.couponUsage = couponUsage;
        this.avgRoi = avgRoi;
        this.campaigns = campaigns;
    }

    public double getTotalRevenue() {
        return totalRevenue;
    }

    public void setTotalRevenue(double totalRevenue) {
        this.totalRevenue = totalRevenue;
    }

    public long getActiveCoupons() {
        return activeCoupons;
    }

    public void setActiveCoupons(long activeCoupons) {
        this.activeCoupons = activeCoupons;
    }

    public long getCouponUsage() {
        return couponUsage;
    }

    public void setCouponUsage(long couponUsage) {
        this.couponUsage = couponUsage;
    }

    public double getAvgRoi() {
        return avgRoi;
    }

    public void setAvgRoi(double avgRoi) {
        this.avgRoi = avgRoi;
    }

    public List<PartnerCampaignSummaryDto> getCampaigns() {
        return campaigns;
    }

    public void setCampaigns(List<PartnerCampaignSummaryDto> campaigns) {
        this.campaigns = campaigns;
    }
}
