package capstone_1.Ecotrack_backend.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import capstone_1.Ecotrack_backend.model.User;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUsername(String username);

    boolean existsByUsername(String username);

    boolean existsByEmail(String email);

    public Optional<User> findByEmail(String email);
}
