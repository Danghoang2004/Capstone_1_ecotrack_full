package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;
import java.util.Map;

public class DashboardResponse {

    private long totalUsers;
    private long totalReports;
    private long totalCampaigns;
    private long totalPoints;

    // ===== THÊM 4 FIELD % TĂNG TRƯỞNG =====
    private Double userGrowthPercent;
    private Double reportGrowthPercent;
    private Double campaignGrowthPercent;
    private Double pointGrowthPercent;

    private List<MonthlyActivityDto> monthlyActivity;
    private Map<String, Long> reportStatus; // PENDING / VERIFIED / REJECTED / CLEANED
    private List<DashboardCampaignParticipationDto> campaignParticipation;
    private List<DashboardLevelDistributionDto> levelDistribution;
    private List<DashboardRecentActivityDto> recentActivities;

    // ===== GET/SET TỔNG QUAN =====
    public long getTotalUsers() {
        return totalUsers;
    }

    public void setTotalUsers(long totalUsers) {
        this.totalUsers = totalUsers;
    }

    public long getTotalReports() {
        return totalReports;
    }

    public void setTotalReports(long totalReports) {
        this.totalReports = totalReports;
    }

    public long getTotalCampaigns() {
        return totalCampaigns;
    }

    public void setTotalCampaigns(long totalCampaigns) {
        this.totalCampaigns = totalCampaigns;
    }

    public long getTotalPoints() {
        return totalPoints;
    }

    public void setTotalPoints(long totalPoints) {
        this.totalPoints = totalPoints;
    }

    // ===== GET/SET % TĂNG TRƯỞNG =====
    public Double getUserGrowthPercent() {
        return userGrowthPercent;
    }

    public void setUserGrowthPercent(Double userGrowthPercent) {
        this.userGrowthPercent = userGrowthPercent;
    }

    public Double getReportGrowthPercent() {
        return reportGrowthPercent;
    }

    public void setReportGrowthPercent(Double reportGrowthPercent) {
        this.reportGrowthPercent = reportGrowthPercent;
    }

    public Double getCampaignGrowthPercent() {
        return campaignGrowthPercent;
    }

    public void setCampaignGrowthPercent(Double campaignGrowthPercent) {
        this.campaignGrowthPercent = campaignGrowthPercent;
    }

    public Double getPointGrowthPercent() {
        return pointGrowthPercent;
    }

    public void setPointGrowthPercent(Double pointGrowthPercent) {
        this.pointGrowthPercent = pointGrowthPercent;
    }

    // ===== GET/SET BIỂU ĐỒ =====
    public List<MonthlyActivityDto> getMonthlyActivity() {
        return monthlyActivity;
    }

    public void setMonthlyActivity(List<MonthlyActivityDto> monthlyActivity) {
        this.monthlyActivity = monthlyActivity;
    }

    public Map<String, Long> getReportStatus() {
        return reportStatus;
    }

    public void setReportStatus(Map<String, Long> reportStatus) {
        this.reportStatus = reportStatus;
    }

    public List<DashboardCampaignParticipationDto> getCampaignParticipation() {
        return campaignParticipation;
    }

    public void setCampaignParticipation(List<DashboardCampaignParticipationDto> campaignParticipation) {
        this.campaignParticipation = campaignParticipation;
    }

    public List<DashboardLevelDistributionDto> getLevelDistribution() {
        return levelDistribution;
    }

    public void setLevelDistribution(List<DashboardLevelDistributionDto> levelDistribution) {
        this.levelDistribution = levelDistribution;
    }

    public List<DashboardRecentActivityDto> getRecentActivities() {
        return recentActivities;
    }

    public void setRecentActivities(List<DashboardRecentActivityDto> recentActivities) {
        this.recentActivities = recentActivities;
    }
}
