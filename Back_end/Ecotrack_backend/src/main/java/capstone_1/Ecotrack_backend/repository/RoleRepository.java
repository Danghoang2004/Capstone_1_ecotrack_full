package capstone_1.Ecotrack_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import capstone_1.Ecotrack_backend.model.Role;

public interface RoleRepository extends JpaRepository<Role, Long> {
    Optional<Role> findByName(String name);
}
