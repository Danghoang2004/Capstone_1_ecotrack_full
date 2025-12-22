package capstone_1.Ecotrack_backend.dto.response;

import java.time.LocalDate;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

public record AdminCampaignListDto(
        Long campaignId,
        String title,
        String locationAddress,
        LocalDate startDate,
        LocalDate endDate,
        Integer maxParticipants,
        Integer currentParticipants,
        Integer rewardPoints,
        String imageUrl,
        String qrCodeUrl,
        String partnerName
) {
}
