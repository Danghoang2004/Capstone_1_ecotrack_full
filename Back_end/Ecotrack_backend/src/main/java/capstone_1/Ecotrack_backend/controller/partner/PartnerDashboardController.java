package capstone_1.Ecotrack_backend.controller.partner;

import capstone_1.Ecotrack_backend.dto.response.PartnerSponsorshipDashboardDto;
import capstone_1.Ecotrack_backend.service.PartnerCurrentUserDashboardService;
import jakarta.servlet.http.HttpServletRequest;

import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/partner")
@CrossOrigin(origins = "*")
public class PartnerDashboardController {

    private final PartnerCurrentUserDashboardService currentUserService;

    public PartnerDashboardController(PartnerCurrentUserDashboardService currentUserService) {
        this.currentUserService = currentUserService;
    }

    @GetMapping("/dashboard/sponsorship")
    public PartnerSponsorshipDashboardDto getDashboard(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            throw new RuntimeException("Missing userId from JWT");
        }
        return currentUserService.getDashboardForUser(userId);
    }
}
