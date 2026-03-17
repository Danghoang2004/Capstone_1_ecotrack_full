package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.model.User; // Import model User của bạn
import capstone_1.Ecotrack_backend.repository.UserRepository; // Import Repository
import capstone_1.Ecotrack_backend.service.CampaignServiceImpl;

import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication; // Import Authentication chuẩn
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/campaigns")
@RequiredArgsConstructor
public class CampaignController {

    private final CampaignServiceImpl service;
    private final UserRepository userRepository;

    @GetMapping("/active")
    public List<CampaignResponse> getActiveCampaigns() {
        return service.getActiveCampaigns();
    }

    @GetMapping
    public List<CampaignResponse> getAllCampaigns() {
        return service.getAllCampaigns();
    }

    @GetMapping("/upcoming")
    public List<CampaignResponse> getUpcomingCampaigns() {
        return service.getUpcomingCampaigns();
    }

    // --- SỬA LẠI: Lấy thông tin user (nếu có) để check trạng thái joined ---
    @GetMapping("/{id}/detail")
    public ResponseEntity<?> getDetail(
            @PathVariable Long id,
            Authentication authentication) {
        Long userId = null;

        if (authentication != null && authentication.isAuthenticated()) {
            String email = authentication.getName();
            userId = userRepository.findByEmail(email)
                    .map(User::getId)
                    .orElse(null);
        }

        return ResponseEntity.ok(service.getDetail(id, userId));
    }

    @PostMapping("/{id}/join")
    public ResponseEntity<?> joinCampaign(
            @PathVariable Long id,
            Authentication authentication) {
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                    .body("Vui lòng đăng nhập để tham gia!");
        }

        try {
            String email = authentication.getName();

            User user = userRepository.findByEmail(email)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng!"));

            service.joinCampaign(id, user.getId());

            return ResponseEntity.ok("Tham gia chiến dịch thành công!");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

}