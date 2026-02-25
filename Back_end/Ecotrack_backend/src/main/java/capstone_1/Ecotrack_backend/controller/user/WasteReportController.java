package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.service.WasteReportService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/user/reports")
@CrossOrigin
public class WasteReportController {

    private final WasteReportService reportService;
    private final CloudinaryService cloudinaryService;

    public WasteReportController(WasteReportService reportService, CloudinaryService cloudinaryService) {
        this.reportService = reportService;
        this.cloudinaryService = cloudinaryService;
    }

    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public ResponseEntity<?> submitReport(
            HttpServletRequest request,
            @RequestParam("title") String title,
            @RequestParam("category") String category,
            @RequestParam("description") String description,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude,
            @RequestParam("status") String status,
            @RequestParam(value = "image", required = false) MultipartFile image) {
        try {
            Long userId = (Long) request.getAttribute("userId");
            if (userId == null) {
                userId = 1L; // Hardcode để test nếu cần
            }

            String imageUrl = null;
            if (image != null && !image.isEmpty()) {
                imageUrl = cloudinaryService.uploadImage(image, "ecotrack/reports");
            }

            WasteReport report = new WasteReport();
            report.setUserId(userId);
            report.setTitle(title);
            report.setCategory(category);
            report.setDescription(description);
            report.setGpsLat(BigDecimal.valueOf(latitude));
            report.setGpsLong(BigDecimal.valueOf(longitude));
            report.setStatus(WasteReport.Status.valueOf(status.toUpperCase()));
            report.setImageUrl(imageUrl);
            report.setCreatedAt(LocalDateTime.now());

            WasteReport saved = reportService.saveReport(report, image);

            Map<String, Object> response = new HashMap<>();
            response.put("success", saved.getStatus() == WasteReport.Status.VERIFIED);
            response.put("status", saved.getStatus().name());
            response.put("points", saved.getStatus() == WasteReport.Status.VERIFIED ? 10 : 0);
            response.put("message",
                    saved.getStatus() == WasteReport.Status.VERIFIED
                            ? "Báo cáo của bạn đã được AI xác thực thành công."
                            : saved.getStatus() == WasteReport.Status.REJECTED
                                    ? "AI không phát hiện rác hoặc ảnh không rõ."
                                    : "Báo cáo đang chờ kiểm duyệt.");

            response.put("time", saved.getCreatedAt());
            response.put("transactionCode", "TXN-" + saved.getReportId());

            return ResponseEntity.ok(response);

        } catch (RuntimeException ex) {
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", ex.getMessage()); // Lấy "Vui lòng chờ thêm X phút..."
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(errorResponse);
        } catch (Exception ex) {
            ex.printStackTrace();
            Map<String, Object> errorResponse = new HashMap<>();
            errorResponse.put("success", false);
            errorResponse.put("message", "Lỗi hệ thống: " + ex.getMessage());
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(errorResponse);
        }
    }

    @GetMapping("")
    public ResponseEntity<List<WasteReport>> getMyReports(HttpServletRequest request) {
        Object userIdObj = request.getAttribute("userId");
        if (userIdObj == null) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED,
                    "Không tìm thấy thông tin người dùng. Vui lòng đăng nhập.");
        }

        Long userId = Long.valueOf(userIdObj.toString());
        List<WasteReport> reports = reportService.getReportsByUser(userId);
        return ResponseEntity.ok(reports);
    }
}