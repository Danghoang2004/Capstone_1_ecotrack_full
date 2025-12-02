package capstone_1.Ecotrack_backend.controller.auth;

import capstone_1.Ecotrack_backend.dto.response.DashboardResponse;
import capstone_1.Ecotrack_backend.service.DashboardService;
import org.springframework.web.bind.annotation.*;

@CrossOrigin(origins = "*") // tạm thời cho mọi origin, sau này giới hạn domain FE
@RestController
@RequestMapping("/api/admin/dashboard")
public class DashboardController {

    private final DashboardService service;

    public DashboardController(DashboardService service) {
        this.service = service;
    }

    @GetMapping
    public DashboardResponse getDashboard() {
        return service.getDashboard();
    }
}
