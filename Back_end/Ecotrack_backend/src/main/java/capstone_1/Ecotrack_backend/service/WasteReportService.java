package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AiDetectionResponse; // Đảm bảo import đúng DTO của bạn
import capstone_1.Ecotrack_backend.dto.response.AdminReportDetailDTO;
import capstone_1.Ecotrack_backend.dto.response.AdminReportListResponse;
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
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

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

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

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
            reportData.setAiConfidence(data.getOverallConfidence());
            reportData.setAiAnalyzedImageUrl(data.getOutputImage());
            try {
                reportData.setAiAnalysisJson(objectMapper.writeValueAsString(data.getTypePercentage()));
            } catch (Exception e) {
                reportData.setAiAnalysisJson("{}");
            }

            if (data.isWaste() && data.getOverallConfidence() >= AI_CONFIDENCE_THRESHOLD) {
                isEligibleForPoints = true;
                reportData.setStatus(WasteReport.Status.VERIFIED);
            } else {
                isEligibleForPoints = false;
                reportData.setStatus(WasteReport.Status.REJECTED);
            }
        } else {
            reportData.setStatus(WasteReport.Status.PENDING);
            isEligibleForPoints = false;
        }
        WasteReport saved = reportRepository.save(reportData);

        if (isEligibleForPoints) {
            processPointsAndNotification(saved, true);
        } else {
            processPointsAndNotification(saved, false);
        }

        // Gửi thông báo cho Admin khi có báo cáo mới
        notifyAdminsNewReport(saved);

        return saved;
    }

    private AiDetectionResponse callAiDetectionService(MultipartFile file) {
        try {

            File tempFile = File.createTempFile("upload", file.getOriginalFilename());
            try (FileOutputStream fos = new FileOutputStream(tempFile)) {
                fos.write(file.getBytes());
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.MULTIPART_FORM_DATA);

            MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
            body.add("file", new FileSystemResource(tempFile));

            HttpEntity<MultiValueMap<String, Object>> requestEntity = new HttpEntity<>(body, headers);

            ResponseEntity<AiDetectionResponse> response = restTemplate.postForEntity(
                    AI_SERVICE_URL, requestEntity, AiDetectionResponse.class);

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
            if (report.getStatus() == WasteReport.Status.REJECTED) {
                message = "AI không phát hiện thấy rác trong ảnh này hoặc độ rõ nét thấp.";
            } else {
                message = "Báo cáo đang chờ nhân viên kiểm duyệt thủ công.";
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

    public boolean updateReportStatus(Long reportId, String newStatusStr) {
        // 1. Tìm báo cáo
        WasteReport report = reportRepository.findById(reportId).orElse(null);
        if (report == null)
            return false;

        try {

            WasteReport.Status newStatus = WasteReport.Status.valueOf(newStatusStr.toUpperCase());
            report.setStatus(newStatus);
            reportRepository.save(report);

            String title = "Cập nhật trạng thái báo cáo";
            String message = "";

            switch (newStatus) {
                case VERIFIED:
                    message = "Báo cáo '" + report.getTitle() + "' của bạn đã được Admin xác thực.";
                    break;
                case REJECTED:
                    message = "Báo cáo '" + report.getTitle() + "' đã bị từ chối.";
                    break;
                case CLEANED:
                    message = "Tuyệt vời! Khu vực bạn báo cáo đã được dọn dẹp sạch sẽ.";
                    break;
                default:
                    message = "Trạng thái báo cáo của bạn đã thay đổi thành " + newStatusStr;
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

    public AdminReportListResponse getAllReportsWithDetails() {

        List<WasteReport> reports = reportRepository.findAllByOrderByCreatedAtDesc();

        List<AdminReportDetailDTO> reportDTOs = reports.stream().map(report -> {
            User user = userRepository.findById(report.getUserId()).orElse(null);
            String userName = "Unknown User";
            String userAvatar = "default_avatar.png";

            if (user != null && user.getUserProfile() != null) {
                userName = user.getUserProfile().getFullName() != null ? user.getUserProfile().getFullName()
                        : user.getUsername();
                userAvatar = user.getUserProfile().getAvatarUrl() != null ? user.getUserProfile().getAvatarUrl()
                        : "default_avatar.png";
            }

            return new AdminReportDetailDTO(
                    report.getReportId(),
                    report.getUserId(),
                    userName,
                    userAvatar,
                    report.getTitle(),
                    report.getDescription(),
                    report.getCategory(),
                    report.getStatus().toString(),
                    report.getGpsLat(),
                    report.getGpsLong(),
                    report.getImageUrl(),
                    report.getAiVerified(),
                    report.getAiConfidence(),
                    report.getCreatedAt());
        }).toList();

        Long totalCount = (long) reports.size();
        Long pendingCount = reports.stream()
                .filter(r -> r.getStatus() == WasteReport.Status.PENDING).count();
        Long verifiedCount = reports.stream()
                .filter(r -> r.getStatus() == WasteReport.Status.VERIFIED).count();
        Long rejectedCount = reports.stream()
                .filter(r -> r.getStatus() == WasteReport.Status.REJECTED).count();
        Long cleanedCount = reports.stream()
                .filter(r -> r.getStatus() == WasteReport.Status.CLEANED).count();

        return new AdminReportListResponse(
                totalCount,
                pendingCount,
                verifiedCount,
                rejectedCount,
                cleanedCount,
                reportDTOs);
    }

    public void notifyAdminsNewReport(WasteReport report) {
        try {

            List<User> admins = userRepository.findAll().stream()
                    .filter(user -> user.getRoles().stream()
                            .anyMatch(role -> "ADMIN".equals(role.getName())))
                    .toList();

            for (User admin : admins) {
                notificationService.createNotification(
                        admin.getId(),
                        NotificationType.SYSTEM,
                        "Báo cáo rác mới",
                        "Có báo cáo mới từ người dùng: " + report.getTitle(),
                        "REPORT",
                        report.getReportId());
            }
        } catch (Exception e) {
            System.err.println("Lỗi khi gửi thông báo cho admin: " + e.getMessage());
        }
    }
}