package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.BroadcastAllNotificationRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.dto.response.BroadcastAllNotificationResult;
import capstone_1.Ecotrack_backend.service.AdminBroadcastNotificationService;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/notifications")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminBroadcastNotificationController {

    private final AdminBroadcastNotificationService broadcastService;

    public AdminBroadcastNotificationController(AdminBroadcastNotificationService broadcastService) {
        this.broadcastService = broadcastService;
    }

    @PostMapping("/broadcast-all")
    public ResponseEntity<ApiResponse<BroadcastAllNotificationResult>> broadcastAll(
            @Valid @RequestBody BroadcastAllNotificationRequest request) {
        BroadcastAllNotificationResult result = broadcastService.broadcastToAllUsers(
                request.getTitle(),
                request.getMessage(),
                request.getNotificationType(),
                request.getTargetType(),
                request.getTargetId());

        return ResponseEntity.ok(
                ApiResponse.success(
                        "NOTIFICATION_BROADCAST_ALL_SUCCESS",
                        "Gui thong bao cho tat ca user thanh congđ",
                        result));
    }
}
