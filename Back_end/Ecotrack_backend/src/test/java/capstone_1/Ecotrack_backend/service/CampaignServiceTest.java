package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.CampaignLikeRepository;
import capstone_1.Ecotrack_backend.repository.CampaignParticipantRepository;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.time.LocalDate;
import java.time.LocalTime;
import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class CampaignServiceTest {

    @Mock
    private CampaignLikeRepository likeRepo;
    @Mock
    private UserRepository userRepository;
    @Mock
    private CampaignParticipantRepository participantRepo;
    @Mock
    private CampaignRepository campaignRepository;
    @Mock
    private PartnerRepository partnerRepository;
    @Mock
    private QRCodeService qrCodeService;
    @Mock
    private EmailService emailService;

    @InjectMocks
    private CampaignServiceImpl service;

    @Test
    @DisplayName("getActiveCampaigns: map đúng Campaign -> CampaignResponse và gọi countParticipants")
    void getActiveCampaigns_mapsResponseAndCountsParticipants() {
        Campaign c1 = new Campaign();
        c1.setCampaignId(10L);
        c1.setTitle("Active 1");
        c1.setDescription("D1");
        c1.setImageUrl("img");
        c1.setStartDate(LocalDate.now().minusDays(1));
        c1.setEndDate(LocalDate.now().plusDays(3));
        c1.setStartTime(LocalTime.of(8, 0));
        c1.setEndTime(LocalTime.of(10, 0));
        c1.setLocationAddress("HN");
        c1.setRewardPoints(50);

        when(campaignRepository.findActiveCampaigns()).thenReturn(List.of(c1));
        when(campaignRepository.countParticipants(10L)).thenReturn(7);

        List<CampaignResponse> out = service.getActiveCampaigns();

        assertThat(out).hasSize(1);
        assertThat(out.get(0).getId()).isEqualTo(10L);
        assertThat(out.get(0).getTitle()).isEqualTo("Active 1");
        assertThat(out.get(0).getParticipants()).isEqualTo(7);
        assertThat(out.get(0).getLocation()).isEqualTo("HN");

        verify(campaignRepository).findActiveCampaigns();
        verify(campaignRepository).countParticipants(10L);
        verifyNoMoreInteractions(campaignRepository);
    }

    @Test
    @DisplayName("getUpcomingCampaigns: map đúng Campaign -> CampaignResponse và gọi countParticipants")
    void getUpcomingCampaigns_mapsResponseAndCountsParticipants() {
        Campaign c1 = new Campaign();
        c1.setCampaignId(11L);
        c1.setTitle("Upcoming 1");
        c1.setDescription("D2");
        c1.setImageUrl("img2");
        c1.setStartDate(LocalDate.now().plusDays(2));
        c1.setEndDate(LocalDate.now().plusDays(5));
        c1.setStartTime(LocalTime.of(9, 30));
        c1.setEndTime(LocalTime.of(11, 0));
        c1.setLocationAddress("HCM");
        c1.setRewardPoints(80);

        when(campaignRepository.findUpcomingCampaigns()).thenReturn(List.of(c1));
        when(campaignRepository.countParticipants(11L)).thenReturn(0);

        List<CampaignResponse> out = service.getUpcomingCampaigns();

        assertThat(out).hasSize(1);
        assertThat(out.get(0).getId()).isEqualTo(11L);
        assertThat(out.get(0).getTitle()).isEqualTo("Upcoming 1");
        assertThat(out.get(0).getParticipants()).isEqualTo(0);
        assertThat(out.get(0).getLocation()).isEqualTo("HCM");

        verify(campaignRepository).findUpcomingCampaigns();
        verify(campaignRepository).countParticipants(11L);
        verifyNoMoreInteractions(campaignRepository);
    }

    @Test
    @DisplayName("getAllCampaigns: lấy findAll và map đúng CampaignResponse")
    void getAllCampaigns_returnsMappedList() {
        Campaign c1 = new Campaign();
        c1.setCampaignId(12L);
        c1.setTitle("Any 1");
        c1.setDescription("D3");
        c1.setImageUrl("img3");
        c1.setStartDate(LocalDate.now());
        c1.setEndDate(LocalDate.now().plusDays(1));
        c1.setStartTime(LocalTime.of(7, 0));
        c1.setEndTime(LocalTime.of(8, 0));
        c1.setLocationAddress("DN");
        c1.setRewardPoints(10);

        when(campaignRepository.findAll()).thenReturn(List.of(c1));
        when(campaignRepository.countParticipants(12L)).thenReturn(2);

        List<CampaignResponse> out = service.getAllCampaigns();

        assertThat(out).hasSize(1);
        assertThat(out.get(0).getId()).isEqualTo(12L);
        assertThat(out.get(0).getTitle()).isEqualTo("Any 1");
        assertThat(out.get(0).getParticipants()).isEqualTo(2);
        assertThat(out.get(0).getRewardPoints()).isEqualTo(10);

        verify(campaignRepository).findAll();
        verify(campaignRepository).countParticipants(12L);
        verifyNoMoreInteractions(campaignRepository);
    }
}

