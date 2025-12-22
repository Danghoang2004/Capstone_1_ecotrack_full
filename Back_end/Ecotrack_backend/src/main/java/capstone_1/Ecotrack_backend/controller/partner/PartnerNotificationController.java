package capstone_1.Ecotrack_backend.controller.partner;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.service.NotificationService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/partner/notifications")
@PreAuthorize("hasAuthority('ROLE_PARTNER')")
public class PartnerNotificationController {

    private final NotificationService notificationService;
    private final UserRepository userRepository;

    public PartnerNotificationController(
            NotificationService notificationService,
            UserRepository userRepository
    ) {
        this.notificationService = notificationService;
        this.userRepository = userRepository;
    }

    @GetMapping
    public ResponseEntity<?> getMyNotifications(Authentication authentication) {

        String subject = authentication.getName(); // email hoặc username

        User user = userRepository.findByEmail(subject)
                .orElseGet(() ->
                        userRepository.findByUsername(subject)
                                .orElseThrow(() -> new RuntimeException("User not found"))
                );

        return ResponseEntity.ok(
                notificationService.getAllForUser(user.getId())
        );
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<?> markAsRead(
            @PathVariable Long id,
            Authentication authentication
    ) {
        String subject = authentication.getName();

        User user = userRepository.findByEmail(subject)
                .orElseGet(() ->
                        userRepository.findByUsername(subject)
                                .orElseThrow(() -> new RuntimeException("User not found"))
                );

        notificationService.markAsRead(user.getId(), id);

        return ResponseEntity.ok().build();
    }
}
