package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.NotificationType;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.BadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserBadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Service
@RequiredArgsConstructor
public class BadgeCheckService {

    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final UserPointsRepository userPointsRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;

    @Transactional
    public void checkAndAwardBadges(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại"));

        UserPoints userPoints = userPointsRepository.findById(userId)
                .orElse(null);

        if (userPoints == null) {
            return;
        }

        Integer currentPoints = userPoints.getPoints();
        List<Badge> allBadges = badgeRepository.findAllByOrderByBadgeIdAsc();

        List<UserBadge> claimedBadges = userBadgeRepository.findByUserId(userId);
        Set<Long> claimedBadgeIds = new HashSet<>();
        claimedBadges.forEach(ub -> claimedBadgeIds.add(ub.getBadge().getBadgeId()));

        for (Badge badge : allBadges) {
            if (badge.getPointsRequired() != null && currentPoints >= badge.getPointsRequired()) {
                if (!claimedBadgeIds.contains(badge.getBadgeId())) {
                    UserBadge userBadge = new UserBadge(user, badge);
                    userBadgeRepository.save(userBadge);
                    claimedBadgeIds.add(badge.getBadgeId());

                    notificationService.createNotification(
                            userId,
                            NotificationType.ACHIEVEMENT,
                            "🎉 Huy hiệu mới!",
                            "Bạn đã nhận được huy hiệu: " + badge.getBadgeName(),
                            "BADGE",
                            badge.getBadgeId());
                }
            }
        }
    }
}
