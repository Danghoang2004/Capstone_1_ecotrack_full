package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.Checkin;
import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;

import capstone_1.Ecotrack_backend.repository.CheckinRepository;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;

@Service
public class CheckinService {

    @Autowired
    private CheckinRepository checkinRepository;
    @Autowired
    private CampaignRepository campaignRepository;
    @Autowired
    private UserRepository userRepository;
    @Autowired
    private UserPointsRepository userPointsRepository;
    @Autowired
    private PointTransactionRepository pointTransactionRepository;
    @Autowired
    private BadgeCheckService badgeCheckService;

    @Transactional
    public Checkin processCheckin(Long userId, Long campaignId) {
        // 1. Kiểm tra tồn tại Campaign và User
        Campaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new RuntimeException("Campaign không tồn tại."));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại."));

        // 2. Kiểm tra xem người dùng đã check-in chưa
        if (checkinRepository.existsByUser_IdAndCampaignCampaignId(userId, campaignId)) {
            throw new RuntimeException("Bạn đã Check-in cho chiến dịch này rồi.");
        }

        // 3. Kiểm tra ngày/giờ chiến dịch
        LocalDateTime now = LocalDateTime.now();
        LocalDate today = now.toLocalDate();
        LocalTime currentTime = now.toLocalTime();

        // Kiểm tra xem đã qua ngày/giờ chiến dịch chưa
        if (today.isAfter(campaign.getEndDate()) ||
                (today.isEqual(campaign.getEndDate()) && campaign.getEndTime() != null
                        && currentTime.isAfter(campaign.getEndTime()))) {
            throw new RuntimeException("Chiến dịch đã kết thúc.");
        }

        // 4. Thực hiện Check-in
        Checkin checkin = new Checkin();
        checkin.setUser(user);
        checkin.setCampaign(campaign);
        Checkin savedCheckin = checkinRepository.save(checkin);

        // 5. Thưởng điểm (nếu có)
        if (campaign.getRewardPoints() > 0) {
            int points = campaign.getRewardPoints();

            // Cập nhật tổng điểm User
            UserPoints userPoints = userPointsRepository.findById(userId)
                    .orElseGet(() -> {
                        UserPoints newPoints = new UserPoints();
                        newPoints.setUserId(userId);
                        newPoints.setPoints(0);
                        return newPoints;
                    });
            userPoints.setPoints(userPoints.getPoints() + points);
            userPointsRepository.save(userPoints);

            // Ghi lại giao dịch điểm
            PointTransaction transaction = new PointTransaction();
            transaction.setUser(user);
            transaction.setActionType(PointTransaction.ActionType.CAMPAIGN);
            transaction.setPoints(points);
            transaction.setDescription("Check-in chiến dịch: " + campaign.getTitle());
            pointTransactionRepository.save(transaction);

            badgeCheckService.checkAndAwardBadges(userId);
        }

        return savedCheckin;
    }
}