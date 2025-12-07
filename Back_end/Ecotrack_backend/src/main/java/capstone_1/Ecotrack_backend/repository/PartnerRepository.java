package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Partner;
import org.springframework.data.jpa.repository.JpaRepository;
import java.util.Optional;

public interface PartnerRepository extends JpaRepository<Partner, Long> {
    Optional<Partner> findByUser_Id(Long id);
}
