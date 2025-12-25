package capstone_1.Ecotrack_backend.dto.response;


import lombok.Data;

@Data
public class CampaignDetailDTO {

    private Long id;
    private String title;
    private String description;
    private String imageUrl;

    private String location;
    private String startDate;
    private String endDate;
    private String timeRange;

    private int maxParticipants;
    private int participantCount;

    private int likeCount;
    private int commentCount;

    private int rewardPoints;

    private boolean joined;
    private boolean liked;
}
