package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Campaign;
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

}
