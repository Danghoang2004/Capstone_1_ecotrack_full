package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.dto.response.CampaignDetailDTO;
import capstone_1.Ecotrack_backend.dto.response.CampaignResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import capstone_1.Ecotrack_backend.service.CampaignService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.temporal.ChronoUnit;
import java.util.List;

@Service
public class CampaignServiceImpl implements CampaignService {
    @Autowired
    private CampaignLikeRepository likeRepo;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private CampaignParticipantRepository participantRepo;

    @Autowired
    private CampaignRepository campaignRepository;

    @Autowired
    private PartnerRepository partnerRepository;

    @Autowired
    private QRCodeService qrCodeService;

    @Autowired
    private EmailService emailService;

    @Override
    @Transactional
    public Campaign createCampaign(CampaignRequestDto request) {
        Campaign campaign = new Campaign();
        campaign.setTitle(request.getTitle());
        campaign.setDescription(request.getDescription());
        campaign.setStartDate(request.getStartDate());
        campaign.setEndDate(request.getEndDate());
        campaign.setStartTime(request.getStartTime());
        campaign.setEndTime(request.getEndTime());
        campaign.setLocationAddress(request.getLocationAddress());
        campaign.setMaxParticipants(request.getMaxParticipants());
        campaign.setImageUrl(request.getImageUrl());
        campaign.setRewardPoints(request.getRewardPoints());

        // Gán Partner nếu có
        if (request.getPartnerId() != null) {
            Partner partner = partnerRepository.findById(request.getPartnerId())
                    .orElseThrow(
                            () -> new RuntimeException("Không tìm thấy Partner với ID: " + request.getPartnerId()));
            campaign.setPartner(partner);
        }

        // 1. Lưu lần đầu để có ID (Auto Increment)
        Campaign savedCampaign = campaignRepository.save(campaign);

        try {
            // 2. Sinh nội dung mã QR (Ví dụ: JSON chứa ID và Action)
            // Format này App sẽ đọc và hiểu đây là mã điểm danh
            String qrContent = "{\"action\":\"CHECKIN\", \"campaignId\":" + savedCampaign.getCampaignId() + "}";

            // 3. Gọi hàm sinh ảnh và lưu vào ổ cứng
            // Kích thước 300x300
            String qrUrl = qrCodeService.generateAndSaveQRCode(
                    savedCampaign.getCampaignId(),
                    qrContent,
                    300, 300);

            // 4. Cập nhật URL ảnh QR vào database
            savedCampaign.setQrCodeUrl(qrUrl);
            return campaignRepository.save(savedCampaign);

        } catch (Exception e) {
            throw new RuntimeException("Lỗi khi tạo QR Code: " + e.getMessage());
        }
    }

    @Override
    @Transactional
    public void joinCampaign(Long campaignId, Long userId) {
        // 1. Kiểm tra chiến dịch có tồn tại không
        Campaign campaign = campaignRepository.findById(campaignId)
                .orElseThrow(() -> new RuntimeException("Chiến dịch không tồn tại!"));

        // 2. Kiểm tra User có tồn tại không
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Người dùng không tồn tại!"));

        // 3. Kiểm tra User đã tham gia chưa (Logic backend chặn trùng)
        boolean isJoined = participantRepo.existsById_CampaignIdAndId_UserId(campaignId, userId);
        if (isJoined) {
            throw new RuntimeException("Bạn đã tham gia chiến dịch này rồi!");
        }

        // 4. Kiểm tra chiến dịch đã đầy chưa
        long currentParticipants = participantRepo.countById_CampaignId(campaignId);
        if (currentParticipants >= campaign.getMaxParticipants()) {
            throw new RuntimeException("Chiến dịch đã đủ số lượng người tham gia!");
        }

        // 5. Kiểm tra thời gian (Optional: Không cho join nếu chiến dịch đã kết thúc)
        // if (campaign.getEndDate().isBefore(LocalDate.now())) { ... }

        // 6. Lưu vào database
        CampaignParticipantId id = new CampaignParticipantId(campaignId, userId);

        CampaignParticipant participant = CampaignParticipant.builder()
                .id(id)
                .campaign(campaign)
                .user(user)
                .joinedAt(java.time.LocalDateTime.now())
                .build();

        participantRepo.save(participant);
        sendJoinCampaignEmail(user, campaign);
    }

    public List<CampaignResponse> getActiveCampaigns() {
        LocalDate today = LocalDate.now();

        return campaignRepository.findActiveCampaigns().stream()
                .map(c -> {
                    // Tính toán số ngày còn lại
                    long daysLeft = 0;
                    if (c.getEndDate() != null) {
                        daysLeft = ChronoUnit.DAYS.between(today, c.getEndDate());
                    }

                    return new CampaignResponse(
                            c.getCampaignId(),
                            c.getTitle(),
                            c.getDescription(),
                            c.getImageUrl(),
                            c.getStartDate() + " " + c.getStartTime() + " - " + c.getEndTime(),
                            campaignRepository.countParticipants(c.getCampaignId()),
                            c.getLocationAddress(),
                            c.getRewardPoints(),
                            (int) (daysLeft < 0 ? 0 : daysLeft) // Thêm trường này vào Response
                    );
                })
                .toList();
    }

    public List<CampaignResponse> getUpcomingCampaigns() {
        LocalDate today = LocalDate.now();

        return campaignRepository.findUpcomingCampaigns().stream()
                .map(c -> {
                    // Tính toán số ngày còn lại (Days Remaining)
                    long daysLeft = 0;
                    if (c.getEndDate() != null) {
                        daysLeft = ChronoUnit.DAYS.between(today, c.getEndDate());
                    }

                    return new CampaignResponse(
                            c.getCampaignId(),
                            c.getTitle(),
                            c.getDescription(),
                            c.getImageUrl(),
                            c.getStartDate() + " " + c.getStartTime() + " - " + c.getEndTime(),
                            campaignRepository.countParticipants(c.getCampaignId()),
                            c.getLocationAddress(),
                            c.getRewardPoints(),
                            (int) (daysLeft < 0 ? 0 : daysLeft) // Gán giá trị vào DTO
                    );
                })
                .toList();
    }

    public CampaignDetailDTO getDetail(Long campaignId, Long userId) {
        var p = campaignRepository.findCampaignDetail(campaignId);

        CampaignDetailDTO dto = new CampaignDetailDTO();
        dto.setId(p.getId());
        dto.setTitle(p.getTitle());
        dto.setDescription(p.getDescription());
        dto.setImageUrl(p.getImageUrl());
        dto.setLocation(p.getLocation());
        dto.setStartDate(p.getStartDate());
        dto.setEndDate(p.getEndDate());
        dto.setTimeRange(p.getTimeRange());
        dto.setMaxParticipants(p.getMaxParticipants());
        dto.setParticipantCount(p.getParticipantCount());
        dto.setLikeCount(p.getLikeCount());
        dto.setCommentCount(p.getCommentCount());
        dto.setRewardPoints(p.getRewardPoints());

        if (userId != null) {
            dto.setJoined(
                    participantRepo.existsById_CampaignIdAndId_UserId(campaignId, userId));
            dto.setLiked(
                    likeRepo.existsByCampaign_CampaignIdAndUser_Id(campaignId, userId));
        }

        return dto;
    }

    private void sendJoinCampaignEmail(User user, Campaign campaign) {

        String subject = "🎉 Cảm ơn bạn đã tham gia chiến dịch " + campaign.getTitle();

        String content = """
        <p>Xin chào <b>%s</b>,</p>

        <p>Cảm ơn bạn đã đăng ký tham gia chiến dịch:</p>

        <h3>%s</h3>

        <p><b>📅 Thời gian:</b> %s %s - %s</p>
        <p><b>📍 Địa điểm:</b> %s</p>

        <p>Chúng tôi rất mong được gặp bạn đúng thời gian và địa điểm đã đăng ký.</p>

        <p>Hãy đến đúng giờ để cùng chung tay vì môi trường 🌱</p>

        <br>
        <p>Trân trọng,</p>
        <p><b>EcoTrack Team</b></p>
        """.formatted(
                user.getUsername(),
                campaign.getTitle(),
                campaign.getStartDate(),
                campaign.getStartTime(),
                campaign.getEndTime(),
                campaign.getLocationAddress()
        );

        emailService.sendMessage(
                "ecotrack.system@gmail.com",   // from
                user.getEmail(),               // to
                subject,
                content
        );
    }

}