package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.model.Checkin;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.service.CheckinService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.Map;

@RestController
@RequestMapping("/api/user/campaigns")
public class UserCampaignController {

    @Autowired
    private CheckinService checkinService;

    @Autowired
    private UserRepository userRepository;

    @PostMapping("/checkin")
    public ResponseEntity<?> checkinCampaign(@RequestBody Map<String, Object> qrData) {
        try {
            // Bước 1: Lấy định danh từ SecurityContext
            // Vì trong JwtAuthenticationFilter bạn lưu user.getEmail() vào Principal,
            // nên .getName() sẽ trả về giá trị Email.
            String emailIdentifier = SecurityContextHolder.getContext().getAuthentication().getName();

            if (emailIdentifier == null || emailIdentifier.equals("anonymousUser")) {
                return ResponseEntity.status(403).body(Map.of("success", false, "message", "Lỗi xác thực: Phiên đăng nhập không hợp lệ."));
            }

            // Bước 2: Tìm User thật trong DB dựa trên EMAIL (Thay vì Username)
            User currentUser = userRepository.findByEmail(emailIdentifier)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy tài khoản với email: " + emailIdentifier));

            // Bước 3: Xử lý dữ liệu QR từ Flutter gửi lên
            if (qrData.get("campaignId") == null) {
                return ResponseEntity.badRequest().body(Map.of("success", false, "message", "Dữ liệu QR thiếu ID chiến dịch."));
            }
            Long campaignId = ((Number) qrData.get("campaignId")).longValue();

            // Bước 4: Gọi service xử lý check-in và cộng điểm
            Checkin result = checkinService.processCheckin(currentUser.getId(), campaignId);

            // Bước 5: Trả về Ticket thành công với dữ liệu thật cho Flutter
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Check-in thành công!",
                    "data", Map.of(
                            "userName", currentUser.getUsername(), // Hoặc currentUser.getFullName() nếu có
                            "campaignTitle", result.getCampaign().getTitle(),
                            "points", result.getCampaign().getRewardPoints(),
                            "checkinTime", LocalDateTime.now().toString(),
                            "transactionId", "TXN-" + result.getCheckinId()
                    )
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("success", false, "message", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("success", false, "message", "Lỗi hệ thống: " + e.getMessage()));
        }
    }
}