package capstone_1.Ecotrack_backend.dto.response;

public class PartnerCampaignSummaryDto {

    private Long campaignId;
    private String title;
    private long participants;
    private Integer rewardPoints;

    public PartnerCampaignSummaryDto() {
    }

    // Constructor dùng trong @Query
    public PartnerCampaignSummaryDto(
            Long campaignId,
            String title,
            long participants,
            Integer rewardPoints) {
        this.campaignId = campaignId;
        this.title = title;
        this.participants = participants;
        this.rewardPoints = rewardPoints;
    }

    public Long getCampaignId() {
        return campaignId;
    }

    public void setCampaignId(Long campaignId) {
        this.campaignId = campaignId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public long getParticipants() {
        return participants;
    }

    public void setParticipants(long participants) {
        this.participants = participants;
    }

    public Integer getRewardPoints() {
        return rewardPoints;
    }

    public void setRewardPoints(Integer rewardPoints) {
        this.rewardPoints = rewardPoints;
    }
}
