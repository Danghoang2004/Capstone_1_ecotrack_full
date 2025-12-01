package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.service.CampaignService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class CampaignServiceImpl implements CampaignService {

    @Autowired
    private CampaignRepository campaignRepository;

    @Autowired
    private PartnerRepository partnerRepository;

    @Autowired
    private QRCodeService qrCodeService; // Service sinh QR đã tạo ở bước trước

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
}