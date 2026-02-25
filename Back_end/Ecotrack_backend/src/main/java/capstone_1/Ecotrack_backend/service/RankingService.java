package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.RankingGroupResponse;
import capstone_1.Ecotrack_backend.dto.response.RankingUserResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
public class RankingService {

    private final UserPointsRepository userPointsRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final WasteReportRepository wasteReportRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final CommunityGroupRepository communityGroupRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<RankingUserResponse> getIndividualRankings() {
        // Lấy tất cả user_points sắp xếp theo points giảm dần
        List<UserPoints> userPointsList = userPointsRepository.findAll()
                .stream()
                .sorted((a, b) -> Integer.compare(b.getPoints(), a.getPoints()))
                .collect(Collectors.toList());

        // Filter chỉ lấy users có role ROLE_USER (không lấy ROLE_ADMIN)
        List<UserPoints> filteredUserPoints = userPointsList.stream()
                .filter(userPoints -> {
                    User user = userRepository.findById(userPoints.getUserId())
                            .orElse(null);
                    if (user == null)
                        return false;
                    // Chỉ lấy users có role ROLE_USER, bỏ qua ROLE_ADMIN
                    return user.getRoles().stream()
                            .anyMatch(role -> "ROLE_USER".equals(role.getName()));
                })
                .collect(Collectors.toList());

        // Chỉ lấy 5 người điểm cao nhất
        int limit = Math.min(5, filteredUserPoints.size());

        return IntStream.range(0, limit)
                .mapToObj(index -> {
                    UserPoints userPoints = filteredUserPoints.get(index);
                    // Fetch User và UserProfile một cách rõ ràng
                    User user = userRepository.findById(userPoints.getUserId())
                            .orElseThrow(() -> new RuntimeException(
                                    "Không tìm thấy user với id: " + userPoints.getUserId()));
                    UserProfile profile = user.getUserProfile();

                    // Lấy số reports (activities)
                    Long reportCount = wasteReportRepository.countByUserId(user.getId());

                    // Lấy số badges
                    Long badgeCount = (long) userBadgeRepository.findByUserId(user.getId()).size();

                    // Logic danh hiệu dựa trên rank
                    int rank = index + 1;
                    List<String> titles;
                    if (rank == 1) {
                        // Top 1: có 2 danh hiệu
                        titles = List.of("Eco Warrior", "Clean Champion");
                    } else {
                        // Top 2-5: chỉ có 1 danh hiệu
                        titles = List.of("Eco Warrior");
                    }

                    RankingUserResponse response = new RankingUserResponse();
                    response.setId(user.getId().toString());
                    response.setRank(rank);
                    response.setUserName(profile != null && profile.getFullName() != null
                            ? profile.getFullName()
                            : user.getUsername());
                    response.setPoints(userPoints.getPoints());
                    response.setAvatarUrl(profile != null ? profile.getAvatarUrl() : null);
                    response.setLocation(profile != null ? profile.getLocation() : null);
                    response.setTitles(titles);
                    response.setActivities(reportCount.intValue());
                    response.setBadges(badgeCount.intValue());

                    return response;
                })
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public List<RankingGroupResponse> getGroupRankings() {
        // Lấy tất cả groups và tính total_score (tổng điểm của tất cả thành viên)
        List<GroupMember> allGroupMembers = groupMemberRepository.findAll();

        // Group by groupId và tính tổng điểm
        Map<Long, Integer> groupScores = allGroupMembers.stream()
                .collect(Collectors.groupingBy(
                        GroupMember::getGroupId,
                        Collectors.summingInt(gm -> {
                            UserPoints userPoints = userPointsRepository.findById(gm.getUserId()).orElse(null);
                            return userPoints != null ? userPoints.getPoints() : 0;
                        })));

        // Sắp xếp theo điểm giảm dần
        List<Map.Entry<Long, Integer>> sortedGroups = groupScores.entrySet().stream()
                .sorted((a, b) -> Integer.compare(b.getValue(), a.getValue()))
                .collect(Collectors.toList());

        // Chỉ lấy 5 nhóm điểm cao nhất
        int limit = Math.min(5, sortedGroups.size());

        return IntStream.range(0, limit)
                .mapToObj(index -> {
                    Map.Entry<Long, Integer> entry = sortedGroups.get(index);
                    Long groupId = entry.getKey();
                    Integer totalScore = entry.getValue();

                    // Lấy thông tin group
                    CommunityGroup group = communityGroupRepository.findById(groupId).orElse(null);

                    List<GroupMember> members = allGroupMembers.stream()
                            .filter(gm -> gm.getGroupId().equals(groupId))
                            .collect(Collectors.toList());

                    // Tính activities (tổng số reports của tất cả thành viên)
                    Integer totalActivities = members.stream()
                            .mapToInt(gm -> {
                                Long count = wasteReportRepository.countByUserId(gm.getUserId());
                                return count.intValue();
                            })
                            .sum();

                    // Logic danh hiệu dựa trên rank cho nhóm
                    int rank = index + 1;
                    List<String> titles;
                    if (rank == 1) {
                        // Top 1: có 2 danh hiệu
                        titles = List.of("Eco Warrior", "Clean Champion");
                    } else {
                        // Top 2-5: chỉ có 1 danh hiệu
                        titles = List.of("Eco Warrior");
                    }

                    RankingGroupResponse response = new RankingGroupResponse();
                    response.setId(groupId.toString());
                    response.setRank(rank);
                    response.setGroupName(group != null ? group.getGroupName() : "Group " + groupId);
                    response.setPoints(totalScore);
                    response.setLogoUrl(null); // Chưa có trong DB
                    response.setLocation(null); // Chưa có trong DB
                    response.setTitles(titles);
                    response.setMembers(members.size());
                    response.setActivities(totalActivities);

                    return response;
                })
                .collect(Collectors.toList());
    }
}
