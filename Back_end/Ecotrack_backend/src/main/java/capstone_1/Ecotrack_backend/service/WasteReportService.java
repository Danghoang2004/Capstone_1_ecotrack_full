package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.*;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.service.NotificationService;

@Service
public class WasteReportService {

    @Autowired
    private final WasteReportRepository report;
    @Autowired
    private PointTransactionRepository pointTransactionRepository;
    @Autowired
    private UserPointsRepository userPointsRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private NotificationService notificationService;

    public WasteReportService(WasteReportRepository report) {
        this.report = report;
    }

    public WasteReport saveReport(WasteReport reportdata) {
        WasteReport saved = report.save(reportdata);
        User user = userRepository.findById(saved.getUserId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));
        PointTransaction tx = new PointTransaction();
        tx.setUser(user);
        tx.setActionType(PointTransaction.ActionType.REPORT);
        tx.setDescription("Báo cáo rác: " + saved.getTitle());
        tx.setPoints(10);
        tx.setCreatedAt(LocalDateTime.now());
        pointTransactionRepository.save(tx);

        // 🔹 Cộng điểm cho user
        UserPoints userPoints = userPointsRepository.findById(saved.getUserId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy điểm của user"));
        userPoints.setPoints(userPoints.getPoints() + 10);
        userPointsRepository.save(userPoints);

        //Tạo thông báo cho người dùng 
         notificationService.createNotification(
                saved.getUserId(),
                NotificationType.CAMPAIGN,
                "Báo cáo rác thành công",
                "Cảm ơn bạn đã gửi báo cáo: " + saved.getTitle(),
                "REPORT",
                saved.getReportId()
        );

        return saved;
        
    }
}
