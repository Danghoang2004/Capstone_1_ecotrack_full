package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.ProfileResponse;
import capstone_1.Ecotrack_backend.exception.GlobalExceptionHandler;
import capstone_1.Ecotrack_backend.service.ProfileService;
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

import java.util.List;

import static org.mockito.ArgumentMatchers.anyLong;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

/**
 * Backend test cho API Lịch sử người dùng (nằm trong GET /api/user/profile).
 * Ánh xạ: TC_LOGIC_03 (401 token hết hạn), TC_EDGE_02 (500 lỗi server).
 */
@WebMvcTest(ProfileController.class)
@AutoConfigureMockMvc(addFilters = false)
@Import(GlobalExceptionHandler.class)
class ProfileControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @MockBean
    private ProfileService profileService;

    @Nested
    @DisplayName("TC_LOGIC_03: Xu ly token het han / thieu (401)")
    class Unauthorized {

        @Test
        @DisplayName("Khong co userId trong request (token thieu/het han) → 401 Unauthorized")
        void getProfile_whenUserIdMissing_returns401() throws Exception {
            mockMvc.perform(get("/api/user/profile")
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isUnauthorized());
        }
    }

    @Nested
    @DisplayName("Hien thi lich su thanh cong (200)")
    class Success {

        @Test
        @DisplayName("Co userId trong request → 200 và body chua recentActivities")
        void getProfile_whenUserIdPresent_returns200WithRecentActivities() throws Exception {
            ProfileResponse response = new ProfileResponse();
            response.setUserId(1L);
            response.setUsername("user1");
            response.setRecentActivities(List.of());
            when(profileService.getProfile(1L)).thenReturn(response);

            mockMvc.perform(get("/api/user/profile")
                            .with(request -> {
                                request.setAttribute("userId", 1L);
                                return request;
                            })
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isOk())
                    .andExpect(jsonPath("$.userId").value(1))
                    .andExpect(jsonPath("$.recentActivities").isArray());

            verify(profileService).getProfile(1L);
        }
    }

    @Nested
    @DisplayName("TC_EDGE_02: Xu ly loi tu Server (500)")
    class ServerError {

        @Test
        @DisplayName("Service nem exception → 500 Internal Server Error")
        void getProfile_whenServiceThrows_returns500() throws Exception {
            when(profileService.getProfile(anyLong()))
                    .thenThrow(new RuntimeException("Database connection failed"));

            mockMvc.perform(get("/api/user/profile")
                            .with(req -> {
                                req.setAttribute("userId", 1L);
                                return req;
                            })
                            .contentType(MediaType.APPLICATION_JSON))
                    .andExpect(status().isInternalServerError());
        }
    }
}
