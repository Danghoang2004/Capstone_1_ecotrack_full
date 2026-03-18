package capstone_1.Ecotrack_backend.dto.response;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

public record AdminCampaignDetailWithNotificationsDto(
    // === Campaign Information ===
    Long campaignId,
    String title,
    String description,
    String locationAddress,
    LocalDate startDate,
    LocalDate endDate,
    LocalTime startTime,
    LocalTime endTime,
    Integer maxParticipants,
    Integer currentParticipants,
    Integer rewardPoints,
    String imageUrl,
    String qrCodeUrl,
    String partnerName,

    // === Notification Statistics ===
    Integer totalNotifications,
    Integer unreadNotificationsCount,
    Integer readNotificationsCount,

    // === Notifications List ===
    List<AdminNotificationDetailDto> notifications
) {}
