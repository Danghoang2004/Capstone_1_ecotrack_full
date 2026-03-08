package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.model.UserBadgeId;
import capstone_1.Ecotrack_backend.repository.BadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserBadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.*;

/**
 * Test backend cho chức năng danh sách huy hiệu (BadgeService).
 * - getAllBadges(): danh sách tất cả huy hiệu hệ thống, sort theo badgeId ASC.
 * - getUserEarnedBadges(): danh sách huy hiệu user đã đạt.
 */
@ExtendWith(MockitoExtension.class)
class BadgeServiceTest {

    @Mock
    private BadgeRepository badgeRepository;

    @Mock
    private UserBadgeRepository userBadgeRepository;

    @Mock
    private UserRepository userRepository;

    @InjectMocks
    private BadgeService badgeService;

    private Badge badge1;
    private Badge badge2;

    @BeforeEach
    void setUp() {
        badge1 = new Badge(1L, "Starter", "Mô tả 1", "/icon1.png", "Yêu cầu 1");
        badge2 = new Badge(2L, "Hero", "Mô tả 2", "/icon2.png", "Yêu cầu 2");
    }

    @Nested
    @DisplayName("getAllBadges() - danh sách huy hiệu hệ thống")
    class GetAllBadges {

        @Test
        @DisplayName("Trả về danh sách BadgeResponse đầy đủ thông tin từ Badge")
        void getAllBadges_returnsMappedBadgeResponses() {
            when(badgeRepository.findAllByOrderByBadgeIdAsc())
                    .thenReturn(List.of(badge1, badge2));

            List<BadgeResponse> result = badgeService.getAllBadges();

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getBadgeId()).isEqualTo(1L);
            assertThat(result.get(0).getBadgeName()).isEqualTo("Starter");
            assertThat(result.get(0).getIconUrl()).isEqualTo("/icon1.png");
            assertThat(result.get(0).getDescription()).isEqualTo("Mô tả 1");
            assertThat(result.get(0).getRequirement()).isEqualTo("Yêu cầu 1");
            assertThat(result.get(0).getAwardedAt()).isNull(); // hệ thống chung, không có thời gian được trao
        }

        @Test
        @DisplayName("Không có huy hiệu nào trong DB → trả về list rỗng, không null")
        void getAllBadges_whenEmpty_returnsEmptyList() {
            when(badgeRepository.findAllByOrderByBadgeIdAsc()).thenReturn(List.of());

            List<BadgeResponse> result = badgeService.getAllBadges();

            assertThat(result).isNotNull().isEmpty();
        }
    }

    @Nested
    @DisplayName("getUserEarnedBadges() - danh sách huy hiệu đã đạt của user")
    class GetUserEarnedBadges {

        @Test
        @DisplayName("User tồn tại → trả list BadgeResponse map từ UserBadge")
        void getUserEarnedBadges_whenUserExists_returnsEarnedBadges() {
            Long userId = 10L;
            User user = new User();
            user.setId(userId);

            when(userRepository.existsById(userId)).thenReturn(true);

            UserBadge ub1 = new UserBadge();
            ub1.setId(new UserBadgeId(userId, 1L));
            ub1.setUser(user);
            ub1.setBadge(badge1);
            ub1.setAwardedAt(LocalDateTime.of(2025, 3, 1, 10, 0));

            UserBadge ub2 = new UserBadge();
            ub2.setId(new UserBadgeId(userId, 2L));
            ub2.setUser(user);
            ub2.setBadge(badge2);
            ub2.setAwardedAt(LocalDateTime.of(2025, 3, 2, 11, 30));

            when(userBadgeRepository.findByUserId(userId))
                    .thenReturn(List.of(ub1, ub2));

            List<BadgeResponse> result = badgeService.getUserEarnedBadges(userId);

            assertThat(result).hasSize(2);
            assertThat(result.get(0).getBadgeId()).isEqualTo(1L);
            assertThat(result.get(0).getBadgeName()).isEqualTo("Starter");
            assertThat(result.get(0).getAwardedAt()).contains("2025-03-01");

            assertThat(result.get(1).getBadgeId()).isEqualTo(2L);
            assertThat(result.get(1).getBadgeName()).isEqualTo("Hero");
            assertThat(result.get(1).getAwardedAt()).contains("2025-03-02");
        }

        @Test
        @DisplayName("User tồn tại nhưng chưa có huy hiệu → trả list rỗng")
        void getUserEarnedBadges_whenUserHasNoBadges_returnsEmptyList() {
            Long userId = 11L;
            when(userRepository.existsById(userId)).thenReturn(true);
            when(userBadgeRepository.findByUserId(userId)).thenReturn(List.of());

            List<BadgeResponse> result = badgeService.getUserEarnedBadges(userId);

            assertThat(result).isNotNull().isEmpty();
        }

        @Test
        @DisplayName("UserId null hoặc không tồn tại → ném RuntimeException 'Không tìm thấy người dùng'")
        void getUserEarnedBadges_whenUserNotFound_throws() {
            when(userRepository.existsById(999L)).thenReturn(false);

            assertThatThrownBy(() -> badgeService.getUserEarnedBadges(null))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Không tìm thấy người dùng");

            assertThatThrownBy(() -> badgeService.getUserEarnedBadges(999L))
                    .isInstanceOf(RuntimeException.class)
                    .hasMessageContaining("Không tìm thấy người dùng");
        }
    }
}

