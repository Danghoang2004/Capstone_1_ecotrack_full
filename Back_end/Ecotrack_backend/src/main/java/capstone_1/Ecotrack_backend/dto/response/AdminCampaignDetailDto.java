package capstone_1.Ecotrack_backend.dto.response;

import java.time.LocalDate;

public record AdminCampaignDetailDto(
        Long campaignId,
        String title,
        String description,
        String locationAddress,
        LocalDate startDate,
        LocalDate endDate,
        Integer maxParticipants,
        Integer rewardPoints,
        Integer currentParticipants,
        String imageUrl,
        String qrCodeUrl
) {}
