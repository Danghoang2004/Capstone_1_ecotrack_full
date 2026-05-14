package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.NotificationResponse;
import capstone_1.Ecotrack_backend.model.AdminBroadcastReadState;
import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.model.NotificationSourceScope;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.AdminBroadcastReadStateRepository;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.Locale;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    @Autowired
    private AdminBroadcastReadStateRepository adminBroadcastReadStateRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private NotificationBroadcastService notificationBroadcastService;

    public List<NotificationResponse> getAllForUser(Long userId) {
        User user = getUser(userId);
        Long lastReadBroadcastId = getLastReadBroadcastId(userId);

        List<NotificationResponse> userEvents = notificationRepository
                .findByUserIdAndSourceScopeOrderByCreatedAtDesc(userId, NotificationSourceScope.USER_EVENT)
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());

        List<NotificationResponse> adminBroadcasts = notificationRepository
                .findBySourceScopeOrderByCreatedAtDesc(NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .stream()
                .filter(notification -> isVisibleToUser(notification, user))
                .map(n -> NotificationResponse.fromEntityWithRead(
                        n,
                        n.getId() <= lastReadBroadcastId))
                .collect(Collectors.toList());

        return mergeAndSortByCreatedAtDesc(userEvents, adminBroadcasts);
    }

    public List<NotificationResponse> getUnreadForUser(Long userId) {
        User user = getUser(userId);
        Long lastReadBroadcastId = getLastReadBroadcastId(userId);

        List<NotificationResponse> userEvents = notificationRepository
                .findByUserIdAndReadFalseAndSourceScopeOrderByCreatedAtDesc(userId, NotificationSourceScope.USER_EVENT)
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());

        List<NotificationResponse> unreadAdminBroadcasts = notificationRepository
                .findBySourceScopeOrderByCreatedAtDesc(NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .stream()
                .filter(notification -> notification.getId() > lastReadBroadcastId)
                .filter(notification -> isVisibleToUser(notification, user))
                .map(n -> NotificationResponse.fromEntityWithRead(n, false))
                .collect(Collectors.toList());

        return mergeAndSortByCreatedAtDesc(userEvents, unreadAdminBroadcasts);
    }

    @Transactional
    public void markAsRead(Long userId, Long notificationId) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (n.getSourceScope() == NotificationSourceScope.ADMIN_BROADCAST_MASTER) {
            markBroadcastAsRead(userId, notificationId);
            return;
        }

        if (n.getUserId() == null || !n.getUserId().equals(userId)) {
            throw new RuntimeException("Khong phai thong bao cua ban");
        }

        n.setRead(true);
    }

    @Transactional
    public Notification createNotification(
            Long userId,
            NotificationType type,
            String title,
            String message,
            String targetType,
            Long targetId) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setNotificationType(type);
        n.setTitle(title);
        n.setMessage(message);
        n.setTargetType(targetType);
        n.setTargetId(targetId);
        n.setSourceScope(NotificationSourceScope.USER_EVENT);
        Notification saved = notificationRepository.save(n);

        notificationBroadcastService.sendNotificationToUser(userId, NotificationResponse.fromEntity(saved));

        return saved;
    }

    private User getUser(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    private boolean isVisibleToUser(Notification notification, User user) {
        if (notification.getSourceScope() != NotificationSourceScope.ADMIN_BROADCAST_MASTER) {
            return true;
        }

        String audience = normalizeAudience(notification.getTargetType());
        if ("ROLE_ALL".equals(audience)) {
            return true;
        }

        return hasRole(user, audience);
    }

    private boolean hasRole(User user, String roleName) {
        return user.getRoles() != null
                && user.getRoles().stream().anyMatch(role -> roleName.equalsIgnoreCase(role.getName()));
    }

    private String normalizeAudience(String rawAudience) {
        if (rawAudience == null || rawAudience.isBlank()) {
            return "ROLE_ALL";
        }

        String audience = rawAudience.trim().toUpperCase(Locale.ROOT);
        return switch (audience) {
            case "USER" -> "ROLE_USER";
            case "PARTNER" -> "ROLE_PARTNER";
            case "ENVIRONMENT" -> "ROLE_ENVIRONMENT";
            case "GLOBAL", "ALL", "ROLE_ALL" -> "ROLE_ALL";
            default -> audience.startsWith("ROLE_") ? audience : "ROLE_" + audience;
        };
    }

    private Long getLastReadBroadcastId(Long userId) {
        return adminBroadcastReadStateRepository.findById(userId)
                .map(AdminBroadcastReadState::getLastReadNotificationId)
                .orElse(0L);
    }

    private void markBroadcastAsRead(Long userId, Long notificationId) {
        AdminBroadcastReadState state = adminBroadcastReadStateRepository.findById(userId)
                .orElseGet(() -> {
                    AdminBroadcastReadState newState = new AdminBroadcastReadState();
                    newState.setUserId(userId);
                    newState.setLastReadNotificationId(0L);
                    return newState;
                });

        if (notificationId > state.getLastReadNotificationId()) {
            state.setLastReadNotificationId(notificationId);
            adminBroadcastReadStateRepository.save(state);
        }
    }

    private List<NotificationResponse> mergeAndSortByCreatedAtDesc(
            List<NotificationResponse> first,
            List<NotificationResponse> second) {
        List<NotificationResponse> merged = new ArrayList<>(first.size() + second.size());
        merged.addAll(first);
        merged.addAll(second);
        merged.sort(Comparator.comparing(NotificationResponse::getCreatedAt,
                Comparator.nullsLast(Comparator.reverseOrder())));
        return merged;
    }
}
