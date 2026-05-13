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

    private static final String ROLE_USER = "ROLE_USER";
    private static final String ROLE_PARTNER = "ROLE_PARTNER";
    private static final String ROLE_ENVIRONMENT = "ROLE_ENVIRONMENT";
    private static final String ROLE_ALL = "ROLE_ALL";

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
        String audienceType = normalizeAudience(targetType);

        User admin = userRepository.findByEmail(adminPrincipal)
                .orElseGet(() -> userRepository.findByUsername(adminPrincipal)
                        .orElseThrow(() -> new RuntimeException("Admin not found")));

        long recipientCount = userRepository.findAll().stream()
                .filter(user -> isRecipientForAudience(user, audienceType))
                .map(User::getId)
                .distinct()
                .count();
        if (recipientCount == 0) {
            return new BroadcastAllNotificationResult(0, notificationType.name());
        }

        Notification master = new Notification();
        master.setUserId(null);
        master.setNotificationType(notificationType);
        master.setTitle(title);
        master.setMessage(message);
        master.setTargetType(audienceType);
        master.setTargetId(targetId);
        master.setCreatedByUserId(admin.getId());
        master.setSourceScope(NotificationSourceScope.ADMIN_BROADCAST_MASTER);
        notificationRepository.save(master);

        return new BroadcastAllNotificationResult(Math.toIntExact(recipientCount), notificationType.name());
    }

    private boolean isRecipientForAudience(User user, String audienceType) {
        if (ROLE_ALL.equals(audienceType)) {
            return hasRole(user, ROLE_USER) || hasRole(user, ROLE_PARTNER) || hasRole(user, ROLE_ENVIRONMENT);
        }
        return hasRole(user, audienceType);
    }

    private boolean hasRole(User user, String roleName) {
        return user.getRoles() != null
                && user.getRoles().stream().anyMatch(role -> roleName.equalsIgnoreCase(role.getName()));
    }

    private String normalizeAudience(String rawAudience) {
        if (rawAudience == null || rawAudience.isBlank()) {
            return ROLE_USER;
        }

        String audience = rawAudience.trim().toUpperCase(Locale.ROOT);
        return switch (audience) {
            case "USER" -> ROLE_USER;
            case "PARTNER" -> ROLE_PARTNER;
            case "ENVIRONMENT" -> ROLE_ENVIRONMENT;
            case "GLOBAL", "ALL", ROLE_ALL -> ROLE_ALL;
            default -> audience.startsWith("ROLE_") ? audience : "ROLE_" + audience;
        };
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
