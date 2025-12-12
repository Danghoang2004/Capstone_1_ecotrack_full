package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AiDetectionResponse; // Đảm bảo import đúng DTO của bạn
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

    // RestTemplate để gọi API Python
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    // URL của FastAPI (Python)
    private static final String AI_SERVICE_URL = "http://localhost:8000/ai/detect-waste";

    public WasteReportService(WasteReportRepository reportRepository) {
        this.reportRepository = reportRepository;
    }

    public WasteReport saveReport(WasteReport reportData, MultipartFile imageFile) {

        // --- CẤU HÌNH CHIẾN THUẬT (Config) ---
        final int MAX_REPORTS_PER_DAY = 10;   // Một ngày chỉ được báo cáo tối đa 10 lần
        final int COOLDOWN_MINUTES = 5;       // Phải chờ 5 phút giữa các lần báo cáo
        final double AI_CONFIDENCE_THRESHOLD = 0.6; // Độ tin cậy tối thiểu của AI (60%)

        Long userId = reportData.getUserId();

        // =================================================================================
        // CHIẾN THUẬT 2: RATE LIMITING (CHẶN SPAM DỰA TRÊN THỜI GIAN & SỐ LƯỢNG)
        // =================================================================================

        // 1. Kiểm tra giới hạn số lượng trong ngày
        LocalDateTime startOfDay = LocalDate.now().atStartOfDay(); // 00:00:00 hôm nay
        long reportsToday = reportRepository.countByUserIdAndCreatedAtAfter(userId, startOfDay);

        if (reportsToday >= MAX_REPORTS_PER_DAY) {
            throw new RuntimeException("Bạn đã đạt giới hạn báo cáo trong ngày (" + MAX_REPORTS_PER_DAY + " lần). Hãy quay lại vào ngày mai nhé!");
        }

        // 2. Kiểm tra thời gian chờ (Cooldown) giữa các lần báo cáo
        WasteReport lastReport = reportRepository.findTopByUserIdOrderByCreatedAtDesc(userId).orElse(null);

        if (lastReport != null) {
            long minutesSinceLast = Duration.between(lastReport.getCreatedAt(), LocalDateTime.now()).toMinutes();
            if (minutesSinceLast < COOLDOWN_MINUTES) {
                throw new RuntimeException("Vui lòng chờ thêm " + (COOLDOWN_MINUTES - minutesSinceLast) + " phút trước khi gửi báo cáo tiếp theo.");
            }
        }

        // =================================================================================
        // GỌI AI SERVICE (XỬ LÝ ẢNH)
        // =================================================================================
        AiDetectionResponse aiResult = null;
        if (imageFile != null && !imageFile.isEmpty()) {
            aiResult = callAiDetectionService(imageFile);
        }

        // =================================================================================
        // CHIẾN THUẬT 3: LOGIC KIỂM DUYỆT BẰNG AI (CHỈ THƯỞNG KHI HỢP LỆ)
        // =================================================================================

        boolean isEligibleForPoints = false; // Mặc định là KHÔNG cộng điểm

        if (aiResult != null && aiResult.isSuccess()) {
            AiDetectionResponse.AiData data = aiResult.getData();

            // Lưu kết quả phân tích vào DB
            reportData.setAiVerified(data.isWaste());
            reportData.setAiConfidence(data.getOverallConfidence());
            reportData.setAiAnalyzedImageUrl(data.getOutputImage());
            try {
                reportData.setAiAnalysisJson(objectMapper.writeValueAsString(data.getTypePercentage()));
            } catch (Exception e) { reportData.setAiAnalysisJson("{}"); }

            // LOGIC QUYẾT ĐỊNH:
            // Chỉ chấp nhận nếu AI bảo là Rác (isWaste=true) VÀ Độ tin cậy >= 60%
            if (data.isWaste() && data.getOverallConfidence() >= AI_CONFIDENCE_THRESHOLD) {
                isEligibleForPoints = true;
                reportData.setStatus(WasteReport.Status.VERIFIED); // Tự động duyệt
            } else {
                // AI bảo không phải rác, hoặc AI không chắc chắn lắm -> Từ chối
                isEligibleForPoints = false;
                reportData.setStatus(WasteReport.Status.REJECTED);
            }
        } else {
            // Trường hợp gọi AI bị lỗi hoặc không có kết quả -> Để PENDING chờ người duyệt thủ công (không cộng điểm ngay)
            reportData.setStatus(WasteReport.Status.PENDING);
            isEligibleForPoints = false;
        }

        // Lưu báo cáo
        WasteReport saved = reportRepository.save(reportData);

        // =================================================================================
        // CỘNG ĐIỂM & THÔNG BÁO (DỰA TRÊN KẾT QUẢ TRÊN)
        // =================================================================================

        if (isEligibleForPoints) {
            // Nếu hợp lệ: Cộng điểm + Thông báo thành công
            processPointsAndNotification(saved, true);
        } else {
            // Nếu không hợp lệ: Chỉ gửi thông báo giải thích (Không cộng điểm)
            processPointsAndNotification(saved, false);
        }

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

    // --- HÀM XỬ LÝ CỘNG ĐIỂM VÀ THÔNG BÁO ---
    private void processPointsAndNotification(WasteReport report, boolean isSuccess) {
        if (isSuccess) {
            // Logic cộng điểm CŨ (giữ nguyên)
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
                    "Báo cáo của bạn đã được AI xác thực thành công.", "REPORT", report.getReportId()
            );
        } else {
            // Logic khi thất bại (Chỉ thông báo)
            String message = "";
            if (report.getStatus() == WasteReport.Status.REJECTED) {
                message = "AI không phát hiện thấy rác trong ảnh này hoặc độ rõ nét thấp.";
            } else {
                message = "Báo cáo đang chờ nhân viên kiểm duyệt thủ công.";
            }

            notificationService.createNotification(
                    report.getUserId(), NotificationType.SYSTEM, "Báo cáo chưa được duyệt",
                    message, "REPORT", report.getReportId()
            );
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
        if (report == null) return false;

        try {
            // 2. Convert String sang Enum
            WasteReport.Status newStatus = WasteReport.Status.valueOf(newStatusStr.toUpperCase());
            report.setStatus(newStatus);
            reportRepository.save(report);

            // 3. Gửi thông báo cho User sở hữu báo cáo đó
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
                    report.getReportId()
            );

            return true;
        } catch (IllegalArgumentException e) {
            // Lỗi nếu gửi lên status không tồn tại trong Enum
            return false;
        }
    }
}