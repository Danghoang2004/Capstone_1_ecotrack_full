package capstone_1.Ecotrack_backend.model;

public interface CampaignDetailProjection {
    Long getId();
    String getTitle();
    String getDescription();
    String getImageUrl();
    String getLocation();
    String getStartDate();
    String getEndDate();
    String getTimeRange();
    int getMaxParticipants();
    int getParticipantCount();
    int getLikeCount();
    int getCommentCount();
    int getRewardPoints();
}
