package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.NotificationSourceScope;
import capstone_1.Ecotrack_backend.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUserIdAndSourceScopeOrderByCreatedAtDesc(Long userId, NotificationSourceScope scope);

    List<Notification> findByUserIdAndSourceScopeNotOrderByCreatedAtDesc(Long userId, NotificationSourceScope scope);

    List<Notification> findByUserIdAndReadFalseOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUserIdAndReadFalseAndSourceScopeOrderByCreatedAtDesc(Long userId,
            NotificationSourceScope scope);

    List<Notification> findByUserIdAndReadFalseAndSourceScopeNotOrderByCreatedAtDesc(Long userId,
            NotificationSourceScope scope);

    List<Notification> findAllByOrderByCreatedAtDesc();

    List<Notification> findBySourceScopeOrderByCreatedAtDesc(NotificationSourceScope sourceScope);

    Optional<Notification> findByIdAndSourceScope(Long id, NotificationSourceScope sourceScope);
}
