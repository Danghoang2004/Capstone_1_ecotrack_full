package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.CampaignComment;
import capstone_1.Ecotrack_backend.model.CampaignLike;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignLikeRepository extends JpaRepository<CampaignLike, Long> {

    boolean existsByCampaign_CampaignIdAndUser_Id(Long campaignId, Long userId);
}
