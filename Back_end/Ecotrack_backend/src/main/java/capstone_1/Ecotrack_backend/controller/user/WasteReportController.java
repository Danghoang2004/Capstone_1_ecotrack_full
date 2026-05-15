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

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;

@RestController
@RequestMapping("/api/user/reports")
@CrossOrigin
public class WasteReportController {

    private final WasteReportService reportService;
    private final CloudinaryService cloudinaryService;
    private final ObjectMapper objectMapper = new ObjectMapper();

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
            response.put("success", true);
            response.put("report_id", saved.getReportId());
            response.put("report_status", saved.getStatus().name());
            response.put("status", saved.getStatus().name());
            response.put("points", saved.getStatus() == WasteReport.Status.AI_VERIFIED ? 10 : 0);
            response.put("message", buildStatusMessage(saved.getStatus()));

            Map<String, Object> aiResult = buildAiResult(saved);
            response.put("ai_result", aiResult);

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

    private String buildStatusMessage(WasteReport.Status status) {
        return switch (status) {
            case AI_VERIFIED, VERIFIED -> "Báo cáo của bạn đã được AI xác thực thành công.";
            case NEED_REVIEW -> "AI phát hiện vật thể có thể là rác nhưng cần admin kiểm duyệt thêm.";
            case REQUEST_REUPLOAD -> "Ảnh chưa đủ rõ hoặc chưa đủ bối cảnh rác. Vui lòng chụp lại ảnh rõ hơn.";
            case PENDING_AI_ANALYSIS, PENDING -> "Báo cáo đang được AI phân tích.";
            case REJECTED -> "AI không phát hiện rác hoặc ảnh không rõ.";
            case CLEANED, APPROVED -> "Báo cáo đã được xử lý.";
        };
    }

    private Map<String, Object> buildAiResult(WasteReport report) {
        Map<String, Object> aiResult = new HashMap<>();
        aiResult.put("is_waste_detected", Boolean.TRUE.equals(report.getAiVerified()));
        aiResult.put("waste_type", report.getAiWasteType());
        aiResult.put("object_confidence_score", report.getAiConfidence());
        aiResult.put("waste_context_score", report.getAiWasteContextScore());
        aiResult.put("final_waste_score", report.getAiFinalWasteScore());
        aiResult.put("waste_area_ratio", report.getAiWasteAreaRatio());
        aiResult.put("object_count", report.getAiObjectCount());
        aiResult.put("severity_score", report.getAiSeverityScore());
        aiResult.put("pollution_level", report.getAiPollutionLevel());
        aiResult.put("severity_description", report.getAiSeverityDescription());
        aiResult.put("recommendation", report.getAiRecommendation());
        aiResult.put("ai_decision", report.getAiDecision());
        aiResult.put("need_manual_review", report.getAiNeedManualReview());
        aiResult.put("error_message", report.getAiErrorMessage());
        aiResult.put("output_image", report.getAiAnalyzedImageUrl());

        try {
            if (report.getAiAnalysisJson() != null && !report.getAiAnalysisJson().isBlank()) {
                Map<String, Object> stored = objectMapper.readValue(
                        report.getAiAnalysisJson(),
                        new TypeReference<Map<String, Object>>() {
                        });
                aiResult.putAll(stored);
            }
        } catch (Exception ignored) {
        }

        return aiResult;
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