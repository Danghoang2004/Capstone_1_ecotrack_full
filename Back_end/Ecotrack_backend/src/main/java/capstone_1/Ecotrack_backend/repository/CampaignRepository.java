package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Campaign;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface CampaignRepository extends JpaRepository<Campaign, Long> {
}
