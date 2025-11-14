package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.ActivityResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.ProfileResponse;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.model.UserProfile;
import capstone_1.Ecotrack_backend.repository.*;
import org.springframework.transaction.annotation.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProfileService {

    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserPointsRepository userPointsRepository;
    private final WasteReportRepository wasteReportRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final LeaderboardRepository leaderboardRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final PointTransactionRepository pointTransactionRepository;

    private final DateTimeFormatter isoFormatter = DateTimeFormatter.ISO_DATE_TIME;

    @Transactional(readOnly = true)
    public ProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));

        UserProfile profile = user.getUserProfile();

        // points
        UserPoints points = userPointsRepository.findById(userId).orElse(null);
        Integer pts = points != null ? points.getPoints() : 0;

        // counts
        Long reportCount = wasteReportRepository.countByUserId(userId);
        Long groupCount = groupMemberRepository.countByUserId(userId);

        // rank
        Integer rank = leaderboardRepository.findRankByUserId(userId).orElse(null);

        // badges
        List<BadgeResponse> badges = userBadgeRepository.findByUserId(userId)
                .stream()
                .map(ub -> {
                    Badge b = ub.getBadge();
                    BadgeResponse br = new BadgeResponse();
                    br.setBadgeId(b.getBadgeId());
                    br.setBadgeName(b.getBadgeName());
                    br.setIconUrl(b.getIconUrl());
                    br.setDescription(b.getDescription());
                    br.setRequirement(b.getRequirement());
                    br.setAwardedAt(ub.getAwardedAt() != null ? ub.getAwardedAt().toString() : null);
                    return br;
                }).collect(Collectors.toList());

        // recent activities (point transactions, newest first, limit 10)
        List<ActivityResponse> activities = pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(userId)
                .stream()
                .map(tx -> {
                    ActivityResponse a = new ActivityResponse();
                    a.setTransactionId(tx.getTransactionId());
                    a.setActionType(tx.getActionType().name());
                    a.setPoints(tx.getPoints());
                    a.setDescription(tx.getDescription());
                    a.setCreatedAt(tx.getCreatedAt().toString());
                    return a;
                }).collect(Collectors.toList());

        ProfileResponse resp = new ProfileResponse();
        resp.setUserId(user.getId());
        resp.setUsername(user.getUsername());
        resp.setEmail(user.getEmail());

        if (profile != null) {
            resp.setFullName(profile.getFullName());
            resp.setAvatarUrl(profile.getAvatarUrl());
            resp.setLocation(profile.getLocation());
            if (profile.getLevel() != null) {
                resp.setLevelName(profile.getLevel().getLevelName());
                resp.setLevelIcon(profile.getLevel().getIconUrl());
                resp.setMinPoints(profile.getLevel().getMinPoints());
                resp.setMaxPoints(profile.getLevel().getMaxPoints());
            }
        }

        resp.setPoints(pts);
        resp.setReportCount(reportCount);
        resp.setGroupCount(groupCount);
        resp.setRank(rank);
        resp.setBadges(badges);
        resp.setRecentActivities(activities);

        return resp;
    }
}
