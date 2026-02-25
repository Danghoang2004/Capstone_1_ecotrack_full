package capstone_1.Ecotrack_backend.dto.response;

import java.time.LocalDate;

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
                String partnerName) {
}
