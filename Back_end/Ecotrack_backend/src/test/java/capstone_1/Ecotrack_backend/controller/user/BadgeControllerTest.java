package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.ApiBadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.service.BadgeService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Nested;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.Arrays;
import java.util.List;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Test API danh sách huy hiệu:
 *  - GET /api/user/badges/all
 *  - GET /api/user/badges/my
 */
@WebMvcTest(BadgeController.class)
@AutoConfigureMockMvc(addFilters = false)
class BadgeControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private BadgeService badgeService;

    @Nested
    @DisplayName("GET /api/user/badges/all - danh sách toàn bộ huy hiệu")
    class GetAllBadges {

        @Test
        @DisplayName("Trả về 200 và data là list BadgeResponse")
        void getAllBadges_returns200WithData() throws Exception {
            List<BadgeResponse> data = Arrays.asList(
                    new BadgeResponse(1L, "Starter", "/icon1.png", "Desc 1", "Req 1", 0, null, false),
                    new BadgeResponse(2L, "Hero", "/icon2.png", "Desc 2", "Req 2", 0, null, false)
            );
            when(badgeService.getAllBadges()).thenReturn(data);

            mockMvc.perform(get("/api/user/badges/all")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.message").value("Lấy danh sách huy hiệu thành công"))
                    .andExpect(jsonPath("$.data").isArray())
                    .andExpect(jsonPath("$.data[0].badgeId").value(1))
                    .andExpect(jsonPath("$.data[0].badgeName").value("Starter"));

            verify(badgeService).getAllBadges();
        }
    }

    @Nested
    @DisplayName("GET /api/user/badges/my - danh sách huy hiệu đã đạt của user")
    class GetMyBadges {

        @Test
        @DisplayName("Không có userId trên request (chưa login / token hết hạn) → 401 + success=false + message=Unauthorized")
        void getMyBadges_whenUserIdMissing_returns401() throws Exception {
            mockMvc.perform(get("/api/user/badges/my")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isUnauthorized())
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.message").value("Unauthorized"));
        }

        @Test
        @DisplayName("User hợp lệ → 200 và data là list BadgeResponse")
        void getMyBadges_whenUserIdPresent_returns200WithData() throws Exception {
            Long userId = 10L;
            List<BadgeResponse> data = Arrays.asList(
                    new BadgeResponse(1L, "Starter", "/icon1.png", "Desc 1", "Req 1", 0, "2025-03-01T10:00:00", true),
                    new BadgeResponse(2L, "Hero", "/icon2.png", "Desc 2", "Req 2", 0, "2025-03-02T11:30:00", true)
            );

            when(badgeService.getUserEarnedBadges(userId)).thenReturn(data);

            mockMvc.perform(get("/api/user/badges/my")
                            .contentType(MediaType.APPLICATION_JSON)
                            .requestAttr("userId", userId))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.success").value(true))
                    .andExpect(jsonPath("$.message").value("Lấy danh sách huy hiệu đã đạt thành công"))
                    .andExpect(jsonPath("$.data").isArray())
                    .andExpect(jsonPath("$.data[0].badgeId").value(1))
                    .andExpect(jsonPath("$.data[0].badgeName").value("Starter"))
                    .andExpect(jsonPath("$.data[0].awardedAt").value("2025-03-01T10:00:00"));

            verify(badgeService).getUserEarnedBadges(userId);
        }

        @Test
        @DisplayName("Service ném RuntimeException (user không tồn tại, …) → 400 Bad Request + success=false + message lỗi")
        void getMyBadges_whenServiceThrows_returns400() throws Exception {
            when(badgeService.getUserEarnedBadges(anyLong()))
                    .thenThrow(new RuntimeException("Không tìm thấy người dùng"));

            mockMvc.perform(get("/api/user/badges/my")
                            .contentType(MediaType.APPLICATION_JSON)
                            .requestAttr("userId", 999L))
                    .andExpect(status().isBadRequest())
                    .andExpect(jsonPath("$.success").value(false))
                    .andExpect(jsonPath("$.message").value("Không tìm thấy người dùng"));
        }
    }
}

