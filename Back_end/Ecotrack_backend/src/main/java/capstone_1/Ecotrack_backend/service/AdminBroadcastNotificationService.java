package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BroadcastAllNotificationResult;
import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.model.NotificationSourceScope;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Locale;

@Service
public class AdminBroadcastNotificationService {

    private final UserRepository userRepository;
    private final NotificationRepository notificationRepository;

    public AdminBroadcastNotificationService(UserRepository userRepository,
            NotificationRepository notificationRepository) {
        this.userRepository = userRepository;
        this.notificationRepository = notificationRepository;
    }

    @Transactional
    public BroadcastAllNotificationResult broadcastToAllUsers(
            String title,
            String message,
            String notificationTypeRaw,
            String targetType,
            Long targetId,
            String adminPrincipal) {
        NotificationType notificationType = parseType(notificationTypeRaw);

        User admin = userRepository.findByEmail(adminPrincipal)
                .orElseGet(() -> userRepository.findByUsername(adminPrincipal)
                        .orElseThrow(() -> new RuntimeException("Admin not found")));

        long userCount = userRepository.count();
        if (userCount == 0) {
            return new BroadcastAllNotificationResult(0, notificationType.name());
        }

        Notification master = new Notification();
        master.setUserId(null);
        master.setNotificationType(notificationType);
        master.setTitle(title);
        master.setMessage(message);
        master.setTargetType(targetType);
        master.setTargetId(targetId);
        master.setCreatedByUserId(admin.getId());
        master.setSourceScope(NotificationSourceScope.ADMIN_BROADCAST_MASTER);
        notificationRepository.save(master);

        return new BroadcastAllNotificationResult(Math.toIntExact(userCount), notificationType.name());
    }

    private NotificationType parseType(String raw) {
        if (raw == null || raw.isBlank()) {
            throw new IllegalArgumentException("notificationType is required");
        }
        try {
            return NotificationType.valueOf(raw.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException ex) {
            throw new IllegalArgumentException(
                    "notificationType is invalid. Allowed: CAMPAIGN, ACHIEVEMENT, REWARD, SYSTEM");
        }
    }
}
