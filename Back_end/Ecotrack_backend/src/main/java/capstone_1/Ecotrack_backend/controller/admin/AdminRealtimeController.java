package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.service.AdminRealtimeSseService;
import org.springframework.http.MediaType;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/admin/realtime")
@CrossOrigin
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminRealtimeController {

    private final AdminRealtimeSseService adminRealtimeSseService;

    public AdminRealtimeController(AdminRealtimeSseService adminRealtimeSseService) {
        this.adminRealtimeSseService = adminRealtimeSseService;
    }

    @GetMapping(value = "/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
    public SseEmitter stream() {
        return adminRealtimeSseService.subscribe();
    }
}