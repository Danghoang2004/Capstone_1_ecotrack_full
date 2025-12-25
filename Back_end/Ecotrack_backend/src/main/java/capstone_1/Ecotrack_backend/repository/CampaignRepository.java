package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.dto.response.PartnerCampaignSummaryDto;
import capstone_1.Ecotrack_backend.model.Campaign;

import capstone_1.Ecotrack_backend.model.CampaignDetailProjection;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CampaignRepository extends JpaRepository<Campaign, Long> {
    @Query("SELECT c FROM Campaign c WHERE CURRENT_DATE BETWEEN c.startDate AND c.endDate")
    List<Campaign> findActiveCampaigns();

    @Query("SELECT c FROM Campaign c WHERE c.startDate > CURRENT_DATE")
    List<Campaign> findUpcomingCampaigns();

    @Query("SELECT COUNT(cp) FROM CampaignParticipant cp WHERE cp.id.campaignId = :campaignId")
    Integer countParticipants(Long campaignId);

    @Query(value = """
            SELECT
            c.campaign_id AS id,
            c.title,
            c.description,
            c.image_url AS imageUrl,
            c.location_address AS location,
            c.start_date AS startDate,
            c.end_date AS endDate,
            CONCAT(c.start_time, ' - ', c.end_time) AS timeRange,
            c.max_participants AS maxParticipants,
            c.reward_points AS rewardPoints,

            COUNT(DISTINCT cp.user_id) AS participantCount,
            COUNT(DISTINCT cl.user_id) AS likeCount,
            COUNT(DISTINCT cc.comment_id) AS commentCount

            FROM campaigns c
            LEFT JOIN campaign_participants cp ON cp.campaign_id = c.campaign_id
            LEFT JOIN campaign_likes cl ON cl.campaign_id = c.campaign_id
            LEFT JOIN campaign_comments cc ON cc.campaign_id = c.campaign_id
            WHERE c.campaign_id = :id
            GROUP BY c.campaign_id
            """, nativeQuery = true)
    CampaignDetailProjection findCampaignDetail(@Param("id") Long id);

    @Query("""
            SELECT new capstone_1.Ecotrack_backend.dto.response.PartnerCampaignSummaryDto(
                c.campaignId,
                c.title,
                COUNT(cp),
                c.rewardPoints
            )
            FROM Campaign c
            LEFT JOIN c.participants cp
            WHERE c.partner.partnerId = :partnerId
            GROUP BY c.campaignId, c.title, c.rewardPoints
            """)
    List<PartnerCampaignSummaryDto> findCampaignSummariesByPartner(Long partnerId);

    @Query("""
            SELECT COALESCE(AVG(c.rewardPoints), 0)
            FROM Campaign c
            WHERE c.partner.partnerId = :partnerId
            """)
    double avgRoiByPartner(Long partnerId);

    @Query("SELECT COUNT(c) FROM Campaign c WHERE CURRENT_DATE BETWEEN c.startDate AND c.endDate")
    long countActiveCampaigns();

    @Query("SELECT COUNT(c) FROM Campaign c WHERE c.startDate > CURRENT_DATE")
    long countUpcomingCampaigns();

    @Query("SELECT COUNT(cp) FROM CampaignParticipant cp")
    long countAllParticipants();

    // Giả sử tính tổng điểm thưởng làm kinh phí tạm thời
    @Query("SELECT SUM(c.rewardPoints) FROM Campaign c")
    Double sumTotalPoints();
}