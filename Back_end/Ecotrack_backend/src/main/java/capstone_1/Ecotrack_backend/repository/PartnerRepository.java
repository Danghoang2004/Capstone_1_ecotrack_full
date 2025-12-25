package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Partner;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface PartnerRepository extends JpaRepository<Partner, Long> {
    Optional<Partner> findByUserId(Long userId);

}
