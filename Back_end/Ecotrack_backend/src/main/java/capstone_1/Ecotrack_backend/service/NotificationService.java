package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.NotificationResponse;
import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;


import java.util.List;
import java.util.stream.Collectors;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    public List<NotificationResponse> getAllForUser(Long userId) {
        return notificationRepository
                .findByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public List<NotificationResponse> getUnreadForUser(Long userId) {
        return notificationRepository
                .findByUserIdAndReadFalseOrderByCreatedAtDesc(userId)
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());
    }

    @Transactional
    public void markAsRead(Long userId, Long notificationId) {
        Notification n = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!n.getUserId().equals(userId)) {
            throw new RuntimeException("Không phải thông báo của bạn");
        }

        n.setRead(true);
    }

    // Gọi hàm này từ các service khác khi muốn tạo thông báo mới
    @Transactional
    public Notification createNotification(
            Long userId,
            NotificationType type,
            String title,
            String message,
            String targetType,
            Long targetId
    ) {
        Notification n = new Notification();
        n.setUserId(userId);
        n.setNotificationType(type);
        n.setTitle(title);
        n.setMessage(message);
        n.setTargetType(targetType);
        n.setTargetId(targetId);
        return notificationRepository.save(n);
    }
}
