package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.ProfileResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.*;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

/**
 * Backend test cho chức năng Lịch sử người dùng (User History / Recent Activities).
 * Ánh xạ: TC_LOGIC_01 (giới hạn 10), TC_LOGIC_02 (sắp xếp), TC_EDGE_01 (mô tả dài).
 */
@ExtendWith(MockitoExtension.class)
class ProfileServiceTest {

    @Mock
    private UserRepository userRepository;
    @Mock
    private UserProfileRepository userProfileRepository;
    @Mock
    private UserPointsRepository userPointsRepository;
    @Mock
    private WasteReportRepository wasteReportRepository;
    @Mock
    private GroupMemberRepository groupMemberRepository;
    @Mock
    private UserBadgeRepository userBadgeRepository;
    @Mock
    private PointTransactionRepository pointTransactionRepository;
    @Mock
    private LevelRepository levelRepository;

    @InjectMocks
    private ProfileService profileService;

    private User user;
    private UserProfile userProfile;
    private UserPoints userPoints;
    private Level level;

    @BeforeEach
    void setUp() {
        user = new User();
        user.setId(1L);
        user.setUsername("testuser");
        user.setEmail("test@example.com");

        userProfile = new UserProfile();
        userProfile.setFullName("Test User");
        userProfile.setAvatarUrl(null);
        userProfile.setLocation(null);
        userProfile.setLevel(level);
        user.setUserProfile(userProfile);
        Role role = new Role();
        role.setName("ROLE_USER");
        user.setRoles(Set.of(role));

        userPoints = new UserPoints();
        userPoints.setUserId(1L);
        userPoints.setPoints(100);

        level = new Level();
        level.setLevelId(1L);
        level.setLevelName("Eco Starter");
        level.setMinPoints(0);
        level.setMaxPoints(500);
        level.setIconUrl("/icon.png");

        when(userRepository.findById(1L)).thenReturn(Optional.of(user));
        when(userPointsRepository.findById(1L)).thenReturn(Optional.of(userPoints));
        when(levelRepository.findLevelByPoints(anyInt())).thenReturn(Optional.of(level));
        when(wasteReportRepository.countByUserId(1L)).thenReturn(0L);
        when(groupMemberRepository.countByUserId(1L)).thenReturn(0L);
        when(userPointsRepository.findAll()).thenReturn(List.of(userPoints));
        when(userBadgeRepository.findByUserId(1L)).thenReturn(List.of());
    }

    @Nested
@DisplayName("TC_LOGIC_01 & TC_LOGIC_02: Lay va sap xep lich su (gioi han 10, moi nhat truoc)")
class LimitAndSortHistory {

    @Test
    @DisplayName("TC_UI_01 tuong ung: Khi khong co lich su -> recentActivities rong")
    void getProfile_whenNoTransactions_returnsEmptyRecentActivities() {
        when(pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(1L))
                .thenReturn(List.of());

        ProfileResponse resp = profileService.getProfile(1L);

        assertThat(resp.getRecentActivities()).isNotNull().isEmpty();
        verify(pointTransactionRepository).findTop10ByUserIdOrderByCreatedAtDesc(1L);
    }

    @Test
    @DisplayName("TC_UI_02 / TC_LOGIC_02: Co du lieu -> danh sach dung, sap xep moi nhat truoc (index 0 la moi nhat)")
    void getProfile_whenHasTransactions_returnsSortedByCreatedAtDesc() {
        LocalDateTime oldest = LocalDateTime.now().minusHours(2);
        LocalDateTime newer = LocalDateTime.now().minusHours(1);
        LocalDateTime newest = LocalDateTime.now();

        PointTransaction t1 = transaction(1L, 10, "Cu nhat", oldest);
        PointTransaction t2 = transaction(2L, 20, "Giua", newer);
        PointTransaction t3 = transaction(3L, 30, "Moi nhat", newest);

        List<PointTransaction> sortedDesc = List.of(t3, t2, t1);
        when(pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(1L))
                .thenReturn(sortedDesc);

        ProfileResponse resp = profileService.getProfile(1L);

        assertThat(resp.getRecentActivities()).hasSize(3);
        assertThat(resp.getRecentActivities().get(0).getTransactionId()).isEqualTo(3L);
        assertThat(resp.getRecentActivities().get(0).getPoints()).isEqualTo(30);
        assertThat(resp.getRecentActivities().get(0).getDescription()).isEqualTo("Moi nhat");
        assertThat(resp.getRecentActivities().get(2).getTransactionId()).isEqualTo(1L);
    }

    @Test
    @DisplayName("TC_LOGIC_01: Repository chi tra toi da 10 -> response co toi da 10 hoat dong")
    void getProfile_whenRepositoryReturnsTen_returnsOnlyTenActivities() {
        List<PointTransaction> tenItems = new ArrayList<>();
        for (int i = 1; i <= 10; i++) {
            tenItems.add(transaction((long) i, i * 5, "Activity " + i, LocalDateTime.now().minusMinutes(i)));
        }
        when(pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(1L))
                .thenReturn(tenItems);

        ProfileResponse resp = profileService.getProfile(1L);

        assertThat(resp.getRecentActivities()).hasSize(10);
        verify(pointTransactionRepository).findTop10ByUserIdOrderByCreatedAtDesc(eq(1L));
    }
}

@Nested
@DisplayName("TC_EDGE_01: Ten/mo ta hoat dong dai (backend tra du, khong cat)")
class LongDescription {

    @Test
    @DisplayName("Mo ta dai hon 100 ky tu van duoc tra ve day du tu backend")
    void getProfile_whenTransactionHasLongDescription_returnsFullDescription() {
        String longDesc = "A".repeat(150);
        PointTransaction tx = transaction(1L, 10, longDesc, LocalDateTime.now());
        when(pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(1L))
                .thenReturn(List.of(tx));

        ProfileResponse resp = profileService.getProfile(1L);

        assertThat(resp.getRecentActivities()).hasSize(1);
        assertThat(resp.getRecentActivities().get(0).getDescription()).hasSize(150);
        assertThat(resp.getRecentActivities().get(0).getDescription()).isEqualTo(longDesc);
    }
}

@Nested
@DisplayName("Mapping: actionType, points, createdAt (ISO)")
class Mapping {

    @Test
    @DisplayName("Map dung actionType, points, createdAt sang ActivityResponse")
    void getProfile_mapsActionTypePointsAndCreatedAt() {
        LocalDateTime at = LocalDateTime.of(2025, 3, 5, 10, 30);
        PointTransaction tx = transaction(1L, -50, "Doi qua", at);
        tx.setActionType(PointTransaction.ActionType.VOUCHER);
        when(pointTransactionRepository.findTop10ByUserIdOrderByCreatedAtDesc(1L))
                .thenReturn(List.of(tx));

        ProfileResponse resp = profileService.getProfile(1L);

        assertThat(resp.getRecentActivities().get(0).getActionType()).isEqualTo("VOUCHER");
        assertThat(resp.getRecentActivities().get(0).getPoints()).isEqualTo(-50);
        assertThat(resp.getRecentActivities().get(0).getCreatedAt()).isNotNull();
        assertThat(resp.getRecentActivities().get(0).getCreatedAt()).contains("2025-03-05");
    }
}

private static PointTransaction transaction(Long id, int points, String description, LocalDateTime createdAt) {
    PointTransaction t = new PointTransaction();
    t.setTransactionId(id);
    t.setPoints(points);
    t.setDescription(description);
    t.setCreatedAt(createdAt);
    t.setActionType(PointTransaction.ActionType.REPORT);
    return t;
}
}