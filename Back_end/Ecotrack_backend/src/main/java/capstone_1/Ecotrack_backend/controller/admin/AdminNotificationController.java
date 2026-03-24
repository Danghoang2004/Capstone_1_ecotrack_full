package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.model.Notification;
import capstone_1.Ecotrack_backend.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Pageable;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;


@RestController
@RequestMapping("/api/admin/notifications")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminNotificationController {

    @Autowired
    private NotificationRepository notificationRepository;

    @GetMapping
    public ResponseEntity<?> getAdminNotifications() {
        Authentication auth = SecurityContextHolder.getContext().getAuthentication();
        String username = auth.getName();
        var notifications = notificationRepository.findAllByOrderByCreatedAtDesc();
        return ResponseEntity.ok(notifications);
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(@PathVariable Long id) {
        Notification n = notificationRepository.findById(id).orElseThrow();
        n.setRead(true);
        notificationRepository.save(n);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @PostMapping("/send-all")
    public ResponseEntity<?> broadcast(@RequestBody Map<String, String> request) {
        return ResponseEntity.ok("Đã gửi thông báo cho tất cả người dùng");
    }

    @GetMapping("/all")
    public ResponseEntity<?> getAllUserNotifications(Pageable pageable) {
        return ResponseEntity.ok(notificationRepository.findAll(pageable));
    }
}
