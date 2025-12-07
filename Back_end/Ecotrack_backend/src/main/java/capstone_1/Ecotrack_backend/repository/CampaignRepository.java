package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.dto.response.PartnerCampaignSummaryDto;
import capstone_1.Ecotrack_backend.model.Campaign;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignRepository extends JpaRepository<Campaign, Long> {
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
}
