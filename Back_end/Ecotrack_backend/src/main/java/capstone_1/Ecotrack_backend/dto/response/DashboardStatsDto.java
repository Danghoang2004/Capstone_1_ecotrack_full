package capstone_1.Ecotrack_backend.dto.response;

public record DashboardStatsDto(
        long activeCampaigns,
        long upcomingCampaigns,
        long totalParticipants,
        double totalBudget
) {}