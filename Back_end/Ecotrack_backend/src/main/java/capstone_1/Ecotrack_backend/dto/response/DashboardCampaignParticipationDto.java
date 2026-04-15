package capstone_1.Ecotrack_backend.dto.response;

public class DashboardCampaignParticipationDto {

    private String month;
    private long participants;

    public DashboardCampaignParticipationDto() {
    }

    public DashboardCampaignParticipationDto(String month, long participants) {
        this.month = month;
        this.participants = participants;
    }

    public String getMonth() {
        return month;
    }

    public void setMonth(String month) {
        this.month = month;
    }

    public long getParticipants() {
        return participants;
    }

    public void setParticipants(long participants) {
        this.participants = participants;
    }
}