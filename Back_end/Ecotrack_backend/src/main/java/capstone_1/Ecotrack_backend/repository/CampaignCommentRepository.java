package capstone_1.Ecotrack_backend.repository;

import java.util.List;

import capstone_1.Ecotrack_backend.model.CampaignComment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignCommentRepository extends JpaRepository<CampaignComment,Long> {
}