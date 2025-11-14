package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.service.WasteReportService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.math.BigDecimal;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDateTime;

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
                throw new RuntimeException("Unauthorized: Missing UserID");
            }
            String imageUrl = null;
            if (image != null && !image.isEmpty()) {

                String uploadDir = "D:/project_Capstone_1_full/Back_end/Ecotrack_backend/uploads/reports/";
                Files.createDirectories(Paths.get(uploadDir));

                String fileName = System.currentTimeMillis() + "_" + image.getOriginalFilename();
                Path filePath = Paths.get(uploadDir + fileName);

                Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

                imageUrl = "/uploads/reports/" + fileName;
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

            return reportService.saveReport(report);

        } catch (Exception ex) {
            throw new RuntimeException("Failed to create report: " + ex.getMessage());
        }
    }
}
