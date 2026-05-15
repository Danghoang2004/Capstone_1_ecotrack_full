package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AiDetectionResponse; // Đảm bảo import đúng DTO của bạn
import capstone_1.Ecotrack_backend.dto.response.AdminGroupedWasteReportResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.FileSystemResource;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.multipart.MultipartFile;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.Comparator;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class WasteReportService {

    @Autowired
    private final WasteReportRepository reportRepository;
    @Autowired
    private PointTransactionRepository pointTransactionRepository;
    @Autowired
    private UserPointsRepository userPointsRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private NotificationService notificationService;
    @Autowired
    private AdminRealtimeSseService adminRealtimeSseService;

    // RestTemplate để gọi API Python
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // URL của FastAPI (Python)
    private static final String AI_SERVICE_URL = "http://localhost:8000/ai/detect-waste";

    public WasteReportService(WasteReportRepository reportRepository) {
        this.reportRepository = reportRepository;
    }

    public WasteReport saveReport(WasteReport reportData, MultipartFile imageFile) {

        final int MAX_REPORTS_PER_DAY = 10;
        final int COOLDOWN_MINUTES = 5;
        final double AI_CONFIDENCE_THRESHOLD = 0.6;

        Long userId = reportData.getUserId();

        LocalDateTime startOfDay = LocalDate.now().atStartOfDay();
        long reportsToday = reportRepository.countByUserIdAndCreatedAtAfter(userId, startOfDay);

        if (reportsToday >= MAX_REPORTS_PER_DAY) {
            throw new RuntimeException("Bạn đã đạt giới hạn báo cáo trong ngày (" + MAX_REPORTS_PER_DAY
                    + " lần). Hãy quay lại vào ngày mai nhé!");
        }

        WasteReport lastReport = reportRepository.findTopByUserIdOrderByCreatedAtDesc(userId).orElse(null);

        if (lastReport != null) {
            long minutesSinceLast = Duration.between(lastReport.getCreatedAt(), LocalDateTime.now()).toMinutes();
            if (minutesSinceLast < COOLDOWN_MINUTES) {
                throw new RuntimeException("Vui lòng chờ thêm " + (COOLDOWN_MINUTES - minutesSinceLast)
                        + " phút trước khi gửi báo cáo tiếp theo.");
            }
        }

        AiDetectionResponse aiResult = null;
        if (imageFile != null && !imageFile.isEmpty()) {
            aiResult = callAiDetectionService(imageFile);
        }

        boolean isEligibleForPoints = false;

        if (aiResult != null && aiResult.isSuccess()) {
            AiDetectionResponse.AiData data = aiResult.getData();

            reportData.setAiVerified(data.isWaste());
            reportData.setAiConfidence(resolveFinalScore(data));
            reportData.setAiAnalyzedImageUrl(data.getOutputImage());
            reportData.setAiWasteType(data.getWasteType());
            reportData.setAiFinalWasteScore(data.getFinalWasteScore());
            reportData.setAiWasteContextScore(data.getWasteContextScore());
            reportData.setAiWasteAreaRatio(data.getWasteAreaRatio());
            reportData.setAiObjectCount(data.getObjectCount());
            reportData.setAiSeverityScore(data.getSeverityScore());
            reportData.setAiPollutionLevel(data.getPollutionLevel());
            reportData.setAiSeverityDescription(data.getSeverityDescription());
            reportData.setAiRecommendation(data.getRecommendation());
            reportData.setAiDecision(data.getAiDecision());
            reportData.setAiNeedManualReview(Boolean.TRUE.equals(data.getNeedManualReview()));
            reportData.setAiErrorMessage(data.getErrorMessage());
            reportData.setAiFalsePositiveReason(data.getFalsePosReason());
            try {
                reportData.setAiAnalysisJson(buildAiAnalysisJson(data));
            } catch (Exception e) {
                reportData.setAiAnalysisJson("{}");
            }

            if ("AI_VERIFIED".equalsIgnoreCase(data.getReportStatus())) {
                isEligibleForPoints = true;
                reportData.setStatus(WasteReport.Status.AI_VERIFIED);
            } else if ("NEED_REVIEW".equalsIgnoreCase(data.getReportStatus())) {
                isEligibleForPoints = false;
                reportData.setStatus(WasteReport.Status.NEED_REVIEW);
            } else if ("REQUEST_REUPLOAD".equalsIgnoreCase(data.getReportStatus())) {
                isEligibleForPoints = false;
                reportData.setStatus(WasteReport.Status.REQUEST_REUPLOAD);
            } else {
                isEligibleForPoints = false;
                reportData.setStatus(WasteReport.Status.NEED_REVIEW);
            }
        } else {
            reportData.setStatus(WasteReport.Status.PENDING_AI_ANALYSIS);
            isEligibleForPoints = false;
        }
        WasteReport saved = reportRepository.save(reportData);

        if (isEligibleForPoints) {
            processPointsAndNotification(saved, true);
        } else {
            processPointsAndNotification(saved, false);
        }

        adminRealtimeSseService.publishReportCreated(saved);
        return saved;
    }

    // --- HÀM GỌI PYTHON FASTAPI (Đã thêm vào đây) ---
    private AiDetectionResponse callAiDetectionService(MultipartFile file) {
        try {
            // 1. Tạo file tạm để gửi đi (RestTemplate cần File resource)
            File tempFile = File.createTempFile("upload", file.getOriginalFilename());
            try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                fos.write(file.getBytes());
            }

            // 2. Chuẩn bị Header và Body cho Request
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new FileSystemResource(tempFile));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            // 3. Gửi POST request sang Python (cổng 8000)
            ResponseEntity<AiDetectionResponse> response = restTemplate.postForEntity(
                    AI_SERVICE_URL, requestEntity, AiDetectionResponse.class);

            // 4. Xóa file tạm sau khi gửi xong để giải phóng bộ nhớ
            tempFile.delete();

            return response.getBody();

        } catch (IOException e) {
            System.err.println("Lỗi IO hoặc lỗi tạo file: " + e.getMessage());
            return null;
        } catch (Exception e) {
            System.err.println("Lỗi khi gọi AI Service (Python có thể chưa chạy): " + e.getMessage());
            return null;
        }
    }

    private Double resolveFinalScore(AiDetectionResponse.AiData data) {
        if (data.getFinalWasteScore() != null) {
            return data.getFinalWasteScore();
        }
        if (data.getObjectConfidenceScore() != null) {
            return data.getObjectConfidenceScore();
        }
        return data.getOverallConfidence();
    }

    private String buildAiAnalysisJson(AiDetectionResponse.AiData data) throws Exception {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("is_waste", data.isWaste());
        payload.put("detected_items", data.getDetectedItems());
        payload.put("waste_type", data.getWasteType());
        payload.put("object_confidence_score", data.getObjectConfidenceScore());
        payload.put("waste_context_score", data.getWasteContextScore());
        payload.put("final_waste_score", data.getFinalWasteScore());
        payload.put("waste_area_ratio", data.getWasteAreaRatio());
        payload.put("object_count", data.getObjectCount());
        payload.put("severity_score", data.getSeverityScore());
        payload.put("pollution_level", data.getPollutionLevel());
        payload.put("severity_description", data.getSeverityDescription());
        payload.put("recommendation", data.getRecommendation());
        payload.put("ai_decision", data.getAiDecision());
        payload.put("report_status", data.getReportStatus());
        payload.put("need_manual_review", data.getNeedManualReview());
        payload.put("error_message", data.getErrorMessage());
        payload.put("image_quality_score", data.getImageQualityScore());
        payload.put("type_percentage", data.getTypePercentage());
        payload.put("output_image", data.getOutputImage());
        payload.put("false_positive_reason", data.getFalsePosReason());
        payload.put("model_a_has_general_object", data.getModelAHasGeneralObject());
        payload.put("model_a_detected_items", data.getModelADetectedItems());
        payload.put("model_a_reason", data.getModelAReason());
        payload.put("model_b_detected_items", data.getModelBDetectedItems());
        payload.put("final_waste_decision", data.getFinalWasteDecision());
        return objectMapper.writeValueAsString(payload);
    }

    private void processPointsAndNotification(WasteReport report, boolean isSuccess) {
        if (isSuccess) {
            User user = userRepository.findById(report.getUserId()).orElseThrow();

            PointTransaction tx = new PointTransaction();
            tx.setUser(user);
            tx.setActionType(PointTransaction.ActionType.REPORT);
            tx.setDescription("Báo cáo rác: " + report.getTitle());
            tx.setPoints(10);
            tx.setCreatedAt(LocalDateTime.now());
            pointTransactionRepository.save(tx);

            UserPoints userPoints = userPointsRepository.findById(report.getUserId()).orElseThrow();
            userPoints.setPoints(userPoints.getPoints() + 10);
            userPointsRepository.save(userPoints);

            notificationService.createNotification(
                    report.getUserId(), NotificationType.CAMPAIGN, "Cộng 10 điểm!",
                    "Báo cáo của bạn đã được AI xác thực thành công.", "REPORT", report.getReportId());
        } else {
            String message = "";
            if (report.getStatus() == WasteReport.Status.REQUEST_REUPLOAD) {
                message = "Ảnh chưa đủ rõ hoặc chưa đủ bối cảnh rác. Vui lòng chụp lại ảnh rõ hơn.";
            } else if (report.getStatus() == WasteReport.Status.NEED_REVIEW) {
                message = "AI phát hiện vật thể có thể là rác nhưng cần admin kiểm duyệt thêm.";
            } else if (report.getStatus() == WasteReport.Status.PENDING_AI_ANALYSIS) {
                message = "Hệ thống đang phân tích ảnh, vui lòng kiểm tra lại sau.";
            } else {
                message = "Đang kiểm duyệt. Chúng mình sẽ xác nhận trong tối đa 24h ";
            }

            notificationService.createNotification(
                    report.getUserId(), NotificationType.SYSTEM, "Báo cáo chưa được duyệt",
                    message, "REPORT", report.getReportId());
        }
    }

    public List<WasteReport> getReportsByUser(Long userId) {
        return reportRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }

    public List<WasteReport> getAllReportsForAdmin() {
        return reportRepository.findAllByOrderByCreatedAtDesc();
    }

    public List<AdminGroupedWasteReportResponse> getAllGroupedReportsForAdmin() {
        List<WasteReport> reports = reportRepository.findAllByOrderByCreatedAtDesc();

        Map<String, List<WasteReport>> reportsByLocation = new LinkedHashMap<>();
        for (WasteReport report : reports) {
            String key = buildLocationKey(report.getGpsLat(), report.getGpsLong(), report.getReportId());
            reportsByLocation.computeIfAbsent(key, ignored -> new java.util.ArrayList<>()).add(report);
        }

        Set<Long> allUserIds = new HashSet<>();
        for (WasteReport report : reports) {
            if (report.getUserId() != null) {
                allUserIds.add(report.getUserId());
            }
        }

        Map<Long, User> userById = userRepository.findAllById(allUserIds)
                .stream()
                .collect(Collectors.toMap(User::getId, u -> u));

        return reportsByLocation.values().stream()
                .map(group -> toGroupedResponse(group, userById))
                .sorted(Comparator.comparing(AdminGroupedWasteReportResponse::getCreatedAt).reversed())
                .toList();
    }

    private AdminGroupedWasteReportResponse toGroupedResponse(
            List<WasteReport> group,
            Map<Long, User> userById) {
        List<WasteReport> sortedGroup = group.stream()
                .sorted(Comparator.comparing(WasteReport::getCreatedAt).reversed())
                .toList();

        WasteReport latest = sortedGroup.get(0);

        AdminGroupedWasteReportResponse response = new AdminGroupedWasteReportResponse();
        response.setReportId(latest.getReportId());
        response.setTitle(latest.getTitle());
        response.setDescription(latest.getDescription());
        response.setImageUrl(latest.getImageUrl());
        response.setGpsLat(latest.getGpsLat());
        response.setGpsLong(latest.getGpsLong());
        response.setStatus(latest.getStatus() != null ? latest.getStatus().name() : "UNKNOWN");
        response.setCreatedAt(latest.getCreatedAt());
        response.setCategory(latest.getCategory());
        response.setAiConfidence(latest.getAiConfidence());
        response.setReportCount(sortedGroup.size());

        Map<Long, AdminGroupedWasteReportResponse.ReporterInfo> reportersByUser = new HashMap<>();
        for (WasteReport report : sortedGroup) {
            Long userId = report.getUserId();
            if (userId == null) {
                continue;
            }

            AdminGroupedWasteReportResponse.ReporterInfo info = reportersByUser.get(userId);
            if (info == null) {
                info = new AdminGroupedWasteReportResponse.ReporterInfo();
                info.setUserId(userId);

                User user = userById.get(userId);
                info.setUsername(user != null ? user.getUsername() : "User #" + userId);
                info.setEmail(user != null ? user.getEmail() : "");
                info.setReportCount(0);
                info.setLatestReportedAt(report.getCreatedAt());
                reportersByUser.put(userId, info);
            }

            info.setReportCount(info.getReportCount() + 1);
            if (info.getLatestReportedAt() == null ||
                    (report.getCreatedAt() != null && report.getCreatedAt().isAfter(info.getLatestReportedAt()))) {
                info.setLatestReportedAt(report.getCreatedAt());
            }
        }

        List<AdminGroupedWasteReportResponse.ReporterInfo> reporters = reportersByUser.values().stream()
                .sorted(Comparator.comparing(AdminGroupedWasteReportResponse.ReporterInfo::getLatestReportedAt).reversed())
                .toList();
        response.setReporters(reporters);
        return response;
    }

    private String buildLocationKey(BigDecimal lat, BigDecimal lng, Long fallbackId) {
        if (lat == null || lng == null) {
            return "NO_GPS_" + fallbackId;
        }

        // Nhóm theo GPS gần đúng 5 chữ số thập phân (~1m) để gom các báo cáo cùng điểm.
        BigDecimal normalizedLat = lat.setScale(5, RoundingMode.HALF_UP);
        BigDecimal normalizedLng = lng.setScale(5, RoundingMode.HALF_UP);
        return normalizedLat.toPlainString() + "_" + normalizedLng.toPlainString();
    }

    public boolean updateReportStatus(Long reportId, String newStatusStr) {
        // 1. Tìm báo cáo
        WasteReport report = reportRepository.findById(reportId).orElse(null);
        if (report == null)
            return false;

        try {
            // 2. Convert String sang Enum
            WasteReport.Status newStatus = WasteReport.Status.valueOf(newStatusStr.toUpperCase());
            report.setStatus(newStatus);
            reportRepository.save(report);

            // 3. Gửi thông báo cho User sở hữu báo cáo đó
            String title = "📋 Cập nhật báo cáo";
            String message = "";

            switch (newStatus) {
                case VERIFIED:
                    message = " Báo cáo \"" + report.getTitle() + "\" xác thực thành công! Cảm ơn bạn 💚";
                    break;
                case REJECTED:
                    message = "Báo cáo \"" + report.getTitle() + "\" không được chấp nhận. Bạn có thể thử lại nhé!";
                    break;
                case CLEANED:
                    message = "Tuyệt vời! Khu vực \"" + report.getTitle() + "\" đã được dọn sạch. Cảm ơn bạn!";
                    break;
                default:
                    message = "Trạng thái báo cáo đã cập nhật: " + newStatusStr;
            }

            notificationService.createNotification(
                    report.getUserId(),
                    NotificationType.SYSTEM,
                    title,
                    message,
                    "REPORT",
                    report.getReportId());

            return true;
        } catch (IllegalArgumentException e) {
            return false;
        }
    }
}