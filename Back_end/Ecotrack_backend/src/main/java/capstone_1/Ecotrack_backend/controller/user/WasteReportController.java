package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.service.WasteReportService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/user/reports")
@CrossOrigin
public class WasteReportController {

    private final WasteReportService reportService;

    public WasteReportController(WasteReportService reportService) {
        this.reportService = reportService;
    }

    @PostMapping(value = "/upload", consumes = "multipart/form-data")
    public WasteReport submitReport(
            HttpServletRequest request,
            @RequestParam("title") String title,
            @RequestParam("category") String category,
            @RequestParam("description") String description,
            @RequestParam("latitude") Double latitude,
            @RequestParam("longitude") Double longitude,
            @RequestParam("status") String status,
            @RequestParam(value = "image", required = false) MultipartFile image
    ) {
        try {
            Long userId = (Long) request.getAttribute("userId");
            if (userId == null) {
                // Tạm thời comment để test nếu chưa có Auth Filter
                // throw new RuntimeException("Unauthorized: Missing UserID");
                userId = 1L; // Hardcode để test nếu cần
            }

            // 1. Lưu ảnh gốc vào ổ cứng của Java Server (như cũ)
            String imageUrl = null;
            if (image != null && !image.isEmpty()) {
                String uploadDir = "D:/project_Capstone_1_full/Back_end/Ecotrack_backend/uploads/reports/";
                Files.createDirectories(Paths.get(uploadDir));
                String fileName = System.currentTimeMillis() + "_" + image.getOriginalFilename();
                Path filePath = Paths.get(uploadDir + fileName);
                Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);
                imageUrl = "/uploads/reports/" + fileName;
            }

            // 2. Tạo đối tượng Report
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

            // 3. Gọi Service (Truyền thêm file ảnh để Service gọi AI)
            return reportService.saveReport(report, image);

        } catch (Exception ex) {
            ex.printStackTrace();
            throw new RuntimeException("Failed to create report: " + ex.getMessage());
        }
    }

    @GetMapping("")
    public ResponseEntity<List<WasteReport>> getMyReports(HttpServletRequest request) {
        // 1. Lấy userId từ attribute mà JwtAuthenticationFilter đã set
        Object userIdObj = request.getAttribute("userId");

        // Kiểm tra an toàn: Nếu filter chưa chạy hoặc lỗi (hoặc endpoint này bị để public nhầm)
        if (userIdObj == null) {
            // Trả về lỗi 401 Unauthorized thay vì ném RuntimeException chung chung
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Không tìm thấy thông tin người dùng. Vui lòng đăng nhập.");
        }

        // Ép kiểu an toàn sang Long
        Long userId = Long.valueOf(userIdObj.toString());

        // 2. Gọi service lấy dữ liệu
        List<WasteReport> reports = reportService.getReportsByUser(userId);

        // 3. Trả về kết quả kèm HTTP Status 200 OK
        return ResponseEntity.ok(reports);
    }
}