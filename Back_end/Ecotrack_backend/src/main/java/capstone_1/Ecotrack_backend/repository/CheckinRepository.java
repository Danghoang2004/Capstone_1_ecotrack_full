package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Checkin;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface CheckinRepository extends JpaRepository<Checkin , Long> {
    boolean existsByUser_IdAndCampaignCampaignId(Long userId, Long campaignId);
}
