package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserProfile;
import org.springframework.data.jpa.repository.JpaRepository;

public interface UserProfileRepository extends JpaRepository<UserProfile,Long> {
}
