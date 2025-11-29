package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.service.CampaignService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize; // Giữ lại
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.GrantedAuthority;

import java.util.Map;

@RestController
@RequestMapping("/api/partner/campaigns")
@CrossOrigin(origins = "*")
public class PartnerCampaignController {

    @Autowired
    private CampaignService campaignService;

    // KHÔNG CẦN PartnerRepository nữa nếu chỉ Admin tạo,
    // nhưng giữ lại vì Admin vẫn cần gán partnerId vào Campaign.
    @Autowired
    private PartnerRepository partnerRepository;

    // API Tạo chiến dịch mới
    // CHỈ CHO PHÉP ROLE_ADMIN truy cập
    @PostMapping("/create")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<?> createCampaign(@RequestBody CampaignRequestDto request) {

        // 1. Lấy thông tin User hiện tại (Kiểm tra này vẫn cần thiết)
        Object principal = SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        if (!(principal instanceof User)) {
            // Thực tế, @PreAuthorize đã ngăn chặn lỗi này, nhưng giữ lại như một lớp bảo vệ
            return ResponseEntity.status(403).body(Map.of("success", false, "message", "Lỗi xác thực người dùng."));
        }

        // *Đã loại bỏ toàn bộ logic kiểm tra vai trò Partner bên trong hàm*
        // vì @PreAuthorize("hasRole('ADMIN')") đã xử lý việc cấp quyền.

        try {
            // 2. (Không bắt buộc) Kiểm tra nếu Admin quên cung cấp Partner ID
            if (request.getPartnerId() == null) {
                return ResponseEntity.badRequest().body(Map.of(
                        "success", false,
                        "message", "Admin phải chỉ định Partner ID cho chiến dịch."
                ));
            }

            // 3. Gọi Service để tạo Campaign
            Campaign newCampaign = campaignService.createCampaign(request);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Tạo chiến dịch và QR Code thành công!",
                    "data", newCampaign,
                    "qrCodeUrl", newCampaign.getQrCodeUrl()
            ));
        } catch (RuntimeException e) {
            // Xử lý các lỗi nghiệp vụ (ví dụ: không tìm thấy Partner)
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of(
                    "success", false,
                    "message", "Lỗi server không xác định: " + e.getMessage()
            ));
        }
    }
}