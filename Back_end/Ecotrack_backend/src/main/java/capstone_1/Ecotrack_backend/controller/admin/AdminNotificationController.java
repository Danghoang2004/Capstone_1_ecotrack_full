package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.response.NotificationResponse;
import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.model.NotificationSourceScope;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/admin/notifications")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminNotificationController {

    @Autowired
    private NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<List<NotificationResponse>> getAdminNotifications() {
        List<NotificationResponse> notifications = notificationRepository
                .findBySourceScopeOrderByCreatedAtDesc(NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .stream()
                .map(NotificationResponse::fromEntity)
                .collect(Collectors.toList());
        return ResponseEntity.ok(notifications);
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        Notification n = notificationRepository
                .findByIdAndSourceScope(id, NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .orElseThrow(() -> new RuntimeException("Admin notification not found"));
        n.setRead(true);
        notificationRepository.save(n);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateNotification(@PathVariable Long id, @RequestBody Map<String, String> updates) {
        Notification n = notificationRepository
                .findByIdAndSourceScope(id, NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .orElseThrow(() -> new RuntimeException("Admin notification not found"));
        
        if (updates.containsKey("title") && updates.get("title") != null) {
            n.setTitle(updates.get("title"));
        }
        if (updates.containsKey("message") && updates.get("message") != null) {
            n.setMessage(updates.get("message"));
        }
        
        notificationRepository.save(n);
        return ResponseEntity.ok(Map.of("success", true, "notification", NotificationResponse.fromEntity(n)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteNotification(@PathVariable Long id) {
        Notification n = notificationRepository
                .findByIdAndSourceScope(id, NotificationSourceScope.ADMIN_BROADCAST_MASTER)
                .orElseThrow(() -> new RuntimeException("Admin notification not found"));
        
        notificationRepository.delete(n);
        return ResponseEntity.ok(Map.of("success", true));
    }
}
