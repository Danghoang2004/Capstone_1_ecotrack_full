package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.ActivityResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.ProfileResponse;
import capstone_1.Ecotrack_backend.dto.response.RankingUserResponse;
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
import java.util.stream.IntStream;

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

        // Tính rank từ user_points (giống RankingService)
        List<UserPoints> userPointsList = userPointsRepository.findAll()
                .stream()
                .sorted((a, b) -> Integer.compare(b.getPoints(), a.getPoints()))
                .collect(Collectors.toList());

        // Filter chỉ lấy users có role ROLE_USER (không lấy ROLE_ADMIN)
        List<UserPoints> filteredUserPoints = userPointsList.stream()
                .filter(userPoints -> {
                    User u = userRepository.findById(userPoints.getUserId())
                            .orElse(null);
                    if (u == null) return false;
                    // Chỉ lấy users có role ROLE_USER, bỏ qua ROLE_ADMIN
                    return u.getRoles().stream()
                            .anyMatch(role -> "ROLE_USER".equals(role.getName()));
                })
                .collect(Collectors.toList());

        // Tính rank của user hiện tại (tính cho TẤT CẢ users có ROLE_USER, không chỉ top 5)
        Integer rank = null;
        for (int i = 0; i < filteredUserPoints.size(); i++) {
            if (filteredUserPoints.get(i).getUserId().equals(userId)) {
                rank = i + 1;
                break;
            }
        }

        // Lấy top 5 users cho ranking (chỉ ROLE_USER)
        int limit = Math.min(5, filteredUserPoints.size());
        List<RankingUserResponse> topRankings = IntStream.range(0, limit)
                .mapToObj(index -> {
                    UserPoints userPoints = filteredUserPoints.get(index);
                    User topUser = userRepository.findById(userPoints.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userPoints.getUserId()));
                    UserProfile topProfile = topUser.getUserProfile();

                    Long topReportCount = wasteReportRepository.countByUserId(topUser.getId());
                    Long topBadgeCount = (long) userBadgeRepository.findByUserId(topUser.getId()).size();

                    int topRank = index + 1;
                    List<String> titles;
                    if (topRank == 1) {
                        titles = List.of("Eco Warrior", "Clean Champion");
                    } else {
                        titles = List.of("Eco Warrior");
                    }

                    RankingUserResponse rankingResponse = new RankingUserResponse();
                    rankingResponse.setId(topUser.getId().toString());
                    rankingResponse.setRank(topRank);
                    rankingResponse.setUserName(topProfile != null && topProfile.getFullName() != null
                            ? topProfile.getFullName()
                            : topUser.getUsername());
                    rankingResponse.setPoints(userPoints.getPoints());
                    rankingResponse.setAvatarUrl(topProfile != null ? topProfile.getAvatarUrl() : null);
                    rankingResponse.setLocation(topProfile != null ? topProfile.getLocation() : null);
                    rankingResponse.setTitles(titles);
                    rankingResponse.setActivities(topReportCount.intValue());
                    rankingResponse.setBadges(topBadgeCount.intValue());

                    return rankingResponse;
                })
                .collect(Collectors.toList());

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
        resp.setTopRankings(topRankings);

        return resp;
    }
}
