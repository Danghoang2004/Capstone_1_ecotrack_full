package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.CampaignChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface CampaignChatMessageRepository extends JpaRepository<CampaignChatMessage, Long> {
    List<CampaignChatMessage> findByCampaignCampaignIdAndIsDeletedFalseOrderByMessageIdDesc(Long campaignId,
            Pageable pageable);

    List<CampaignChatMessage> findByCampaignCampaignIdAndIsDeletedFalseAndMessageIdGreaterThanOrderByMessageIdAsc(
            Long campaignId,
            Long afterMessageId,
            Pageable pageable);
}
