package capstone_1.Ecotrack_backend.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;
import java.time.LocalDate;
import java.time.LocalTime;

@Data
public class CampaignRequestDto {
    private String title;
    private String description;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate startDate;

    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate endDate;

    // Sử dụng H:m:s để chấp nhận cả "16:0:00" và "16:00:00"
    @JsonFormat(pattern = "[HH:mm:ss][H:m:ss][HH:mm][H:m]")
    private LocalTime startTime;

    @JsonFormat(pattern = "[HH:mm:ss][H:m:ss][HH:mm][H:m]")
    private LocalTime endTime;

    private String locationAddress;
    private Integer maxParticipants;
    private String imageUrl;
    private Integer rewardPoints;
    private Long partnerId;
}