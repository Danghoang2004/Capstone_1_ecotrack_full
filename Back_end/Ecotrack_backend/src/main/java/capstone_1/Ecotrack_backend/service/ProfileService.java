package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.ActivityResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.ProfileResponse;
import capstone_1.Ecotrack_backend.dto.response.RankingUserResponse;
import capstone_1.Ecotrack_backend.model.*;
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

    // TIÊM THÊM REPOSITORY LEVEL
    private final LevelRepository levelRepository;

    private final DateTimeFormatter isoFormatter = DateTimeFormatter.ISO_DATE_TIME;

    @Transactional
    public ProfileResponse getProfile(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));

        UserProfile profile = user.getUserProfile();

        // 1. LẤY SỐ ĐIỂM HIỆN TẠI
        UserPoints points = userPointsRepository.findById(userId).orElse(null);
        Integer pts = points != null ? points.getPoints() : 0;

        // 2. TÌM LEVEL TƯƠNG ỨNG VỚI SỐ ĐIỂM (Logic mới)
        Level currentLevel = levelRepository.findLevelByPoints(pts)
                .orElseGet(() -> levelRepository.findMaxLevel());

        // --- GIỮ NGUYÊN CÁC LOGIC KHÔNG LIÊN QUAN ---

        // counts
        Long reportCount = wasteReportRepository.countByUserId(userId);
        Long groupCount = groupMemberRepository.countByUserId(userId);

        // Tính rank từ user_points
        List<UserPoints> userPointsList = userPointsRepository.findAll()
                .stream()
                .sorted((a, b) -> Integer.compare(b.getPoints(), a.getPoints()))
                .collect(Collectors.toList());

        List<UserPoints> filteredUserPoints = userPointsList.stream()
                .filter(userPoints -> {
                    User u = userRepository.findById(userPoints.getUserId()).orElse(null);
                    if (u == null) return false;
                    return u.getRoles().stream().anyMatch(role -> "ROLE_USER".equals(role.getName()));
                })
                .collect(Collectors.toList());

        Integer rank = null;
        for (int i = 0; i < filteredUserPoints.size(); i++) {
            if (filteredUserPoints.get(i).getUserId().equals(userId)) {
                rank = i + 1;
                break;
            }
        }

        // Lấy top 5 users
        int limit = Math.min(5, filteredUserPoints.size());
        List<RankingUserResponse> topRankings = IntStream.range(0, limit)
                .mapToObj(index -> {
                    UserPoints userPoints = filteredUserPoints.get(index);
                    User topUser = userRepository.findById(userPoints.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));
                    UserProfile topProfile = topUser.getUserProfile();
                    Long topReportCount = wasteReportRepository.countByUserId(topUser.getId());
                    Long topBadgeCount = (long) userBadgeRepository.findByUserId(topUser.getId()).size();

                    int topRank = index + 1;
                    List<String> titles = (topRank == 1) ? List.of("Eco Warrior", "Clean Champion") : List.of("Eco Warrior");

                    RankingUserResponse rankingResponse = new RankingUserResponse();
                    rankingResponse.setId(topUser.getId().toString());
                    rankingResponse.setRank(topRank);
                    rankingResponse.setUserName(topProfile != null && topProfile.getFullName() != null ? topProfile.getFullName() : topUser.getUsername());
                    rankingResponse.setPoints(userPoints.getPoints());
                    rankingResponse.setAvatarUrl(topProfile != null ? topProfile.getAvatarUrl() : null);
                    rankingResponse.setLocation(topProfile != null ? topProfile.getLocation() : null);
                    rankingResponse.setTitles(titles);
                    rankingResponse.setActivities(topReportCount.intValue());
                    rankingResponse.setBadges(topBadgeCount.intValue());
                    return rankingResponse;
                }).collect(Collectors.toList());

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

        // recent activities
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

        // --- MAPPING DATA VÀO RESPONSE ---
        ProfileResponse resp = new ProfileResponse();
        resp.setUserId(user.getId());
        resp.setUsername(user.getUsername());
        resp.setEmail(user.getEmail());

        if (profile != null) {
            resp.setFullName(profile.getFullName());
            resp.setAvatarUrl(profile.getAvatarUrl());
            resp.setLocation(profile.getLocation());

            // 3. CẬP NHẬT THÔNG TIN LEVEL VÀO RESPONSE
            if (currentLevel != null) {
                resp.setLevelName(currentLevel.getLevelName());
                resp.setLevelIcon(currentLevel.getIconUrl());
                resp.setMinPoints(currentLevel.getMinPoints());
                resp.setMaxPoints(currentLevel.getMaxPoints());

                // Đồng bộ lại Level vào bảng user_profile nếu có sự thay đổi
                if (profile.getLevel() == null || !profile.getLevel().getLevelId().equals(currentLevel.getLevelId())) {
                    profile.setLevel(currentLevel);
                    userProfileRepository.save(profile);
                }
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