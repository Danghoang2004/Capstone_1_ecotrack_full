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

    @JsonFormat(pattern = "HH:mm")
    private LocalTime startTime;

    @JsonFormat(pattern = "HH:mm")
    private LocalTime endTime;

    private String locationAddress;
    private Integer maxParticipants;
    private String imageUrl; // Link ảnh bìa chiến dịch (upload trước đó)
    private Integer rewardPoints;

    private Long partnerId; // ID của đối tác tổ chức (nếu có)
}