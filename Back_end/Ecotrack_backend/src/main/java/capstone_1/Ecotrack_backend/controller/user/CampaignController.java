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
import java.util.Optional;

@RestController
@RequestMapping("/api/campaigns")
@RequiredArgsConstructor
public class CampaignController {

    private final CampaignServiceImpl service;
    private final UserRepository userRepository; // 1. Inject UserRepository

    @GetMapping("/active")
    public List<CampaignResponse> getActiveCampaigns() {
        return service.getActiveCampaigns();
    }

    @GetMapping("/upcoming")
    public List<CampaignResponse> getUpcomingCampaigns() {
        return service.getUpcomingCampaigns();
    }

    // --- SỬA LẠI: Lấy thông tin user (nếu có) để check trạng thái joined ---
    @GetMapping("/{id}/detail")
    public ResponseEntity<?> getDetail(
            @PathVariable Long id,
            Authentication authentication // Inject Authentication
    ) {
        Long userId = null;

        // Kiểm tra xem user có đăng nhập không
        if (authentication != null && authentication.isAuthenticated()) {
            String username = authentication.getName(); // Lấy username
            Optional<User> user = userRepository.findByUsername(username);
            if (user.isPresent()) {
                userId = user.get().getId();
            }
        }

        return ResponseEntity.ok(service.getDetail(id, userId));
    }

    // --- SỬA LẠI: Join campaign dùng Authentication ---
    @PostMapping("/{id}/join")
    public ResponseEntity<?> joinCampaign(
            @PathVariable Long id,
            Authentication authentication
    ) {
        // 1. Kiểm tra đăng nhập
        if (authentication == null || !authentication.isAuthenticated()) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body("Vui lòng đăng nhập để tham gia!");
        }

        try {
            // 2. Lấy username từ token/session
            String username = authentication.getName();

            // 3. Tìm User ID từ Database dựa trên username
            User user = userRepository.findByUsername(username)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy người dùng!"));

            // 4. Gọi service với ID tìm được
            service.joinCampaign(id, user.getId());

            return ResponseEntity.ok("Tham gia chiến dịch thành công!");
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Lỗi hệ thống");
        }
    }
}