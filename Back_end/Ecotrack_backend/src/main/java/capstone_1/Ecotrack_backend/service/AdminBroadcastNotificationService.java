package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BroadcastAllNotificationResult;
import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.List;
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
            Long targetId) {
        NotificationType notificationType = parseType(notificationTypeRaw);

        var users = userRepository.findAll();
        if (users.isEmpty()) {
            return new BroadcastAllNotificationResult(0, notificationType.name());
        }

        List<Notification> notifications = new ArrayList<>(users.size());
        for (var user : users) {
            Notification n = new Notification();
            n.setUserId(user.getId());
            n.setNotificationType(notificationType);
            n.setTitle(title);
            n.setMessage(message);
            n.setTargetType(targetType);
            n.setTargetId(targetId);
            notifications.add(n);
        }

        notificationRepository.saveAll(notifications);
        return new BroadcastAllNotificationResult(notifications.size(), notificationType.name());
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
