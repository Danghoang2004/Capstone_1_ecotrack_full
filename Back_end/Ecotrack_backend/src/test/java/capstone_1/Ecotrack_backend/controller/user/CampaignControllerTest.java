package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.service.CampaignServiceImpl;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;

import java.util.List;

import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(controllers = CampaignController.class)
@AutoConfigureMockMvc(addFilters = false)
class CampaignControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private CampaignServiceImpl service;

    @MockBean
    private UserRepository userRepository;

    @Test
    @DisplayName("GET /api/campaigns trả về list campaigns")
    void getAllCampaigns_returnsOk() throws Exception {
        when(service.getAllCampaigns()).thenReturn(List.of(
                new CampaignResponse(1L, "T1", "D1", "img", "dt", 3, "HN", 10, 1)
        ));

        mockMvc.perform(get("/api/campaigns").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(1))
                .andExpect(jsonPath("$[0].title").value("T1"));
    }

    @Test
    @DisplayName("GET /api/campaigns/active trả về list campaigns active")
    void getActiveCampaigns_returnsOk() throws Exception {
        when(service.getActiveCampaigns()).thenReturn(List.of(
                new CampaignResponse(2L, "A1", "D", "img", "dt", 1, "HCM", 5, 2)
        ));

        mockMvc.perform(get("/api/campaigns/active").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(2))
                .andExpect(jsonPath("$[0].title").value("A1"));
    }

    @Test
    @DisplayName("GET /api/campaigns/upcoming trả về list campaigns upcoming")
    void getUpcomingCampaigns_returnsOk() throws Exception {
        when(service.getUpcomingCampaigns()).thenReturn(List.of(
                new CampaignResponse(3L, "U1", "D", "img", "dt", 0, "DN", 7, 5)
        ));

        mockMvc.perform(get("/api/campaigns/upcoming").accept(MediaType.APPLICATION_JSON))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$[0].id").value(3))
                .andExpect(jsonPath("$[0].title").value("U1"));
    }
}

