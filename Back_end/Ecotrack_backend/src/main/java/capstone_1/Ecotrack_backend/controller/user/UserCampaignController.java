package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.model.User; // Cần import Model User
import capstone_1.Ecotrack_backend.service.CheckinService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder; // Import cần thiết
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/user/campaigns")
public class UserCampaignController {

    @Autowired
    private CheckinService checkinService;

    @PostMapping("/checkin")
    public ResponseEntity<?> checkinCampaign(
            // Loại bỏ @AuthenticationPrincipal UserDetails userDetails
            // vì chúng ta đã lưu toàn bộ Object User vào SecurityContext
            @RequestBody Map<String, Object> qrData) {

        try {
            // Lấy Object User THẬT từ Security Context
            Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            if (!(principal instanceof User)) {
                return ResponseEntity.status(403).body(Map.of("success", false, "message", "Lỗi xác thực người dùng."));
            }
            User currentUser = (User) principal;
            Long userId = currentUser.getId(); // Lấy ID THẬT từ Object User đã được xác thực

            // Xử lý dữ liệu QR
            Long campaignId = ((Number) qrData.get("campaignId")).longValue();
            String action = (String) qrData.get("action");

            if (!"CHECKIN".equals(action)) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Mã QR không hợp lệ."));
            }

            checkinService.processCheckin(userId, campaignId);

            return ResponseEntity.ok(Map.of("success", true, "message", "Check-in thành công! Bạn nhận được điểm thưởng."));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("success", false, "message", "Lỗi server: " + e.getMessage()));
        }
    }
}