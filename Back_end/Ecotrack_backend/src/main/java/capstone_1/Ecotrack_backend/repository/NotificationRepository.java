package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {

    List<Notification> findByUserIdOrderByCreatedAtDesc(Long userId);

    List<Notification> findByUserIdAndReadFalseOrderByCreatedAtDesc(Long userId);

    List<Notification> findAllByOrderByCreatedAtDesc();

    List<Notification> findByTargetTypeAndTargetIdOrderByCreatedAtDesc(String targetType, Long targetId);
}
