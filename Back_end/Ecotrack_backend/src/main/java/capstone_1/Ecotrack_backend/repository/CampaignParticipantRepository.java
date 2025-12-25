package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.CampaignParticipant;
import capstone_1.Ecotrack_backend.model.CampaignParticipantId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignParticipantRepository
        extends JpaRepository<CampaignParticipant, CampaignParticipantId> {
    boolean existsById_CampaignIdAndId_UserId(Long campaignId, Long userId);

    long countById_CampaignId(Long campaignId);
}