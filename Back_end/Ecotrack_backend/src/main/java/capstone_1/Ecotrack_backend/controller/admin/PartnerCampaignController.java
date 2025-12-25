package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.CampaignRequestDto;
import capstone_1.Ecotrack_backend.dto.response.AdminCampaignDetailDto;
import capstone_1.Ecotrack_backend.dto.response.AdminCampaignListDto;
import capstone_1.Ecotrack_backend.dto.response.DashboardStatsDto;
import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.CampaignParticipantRepository;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.service.CampaignService;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize; // Giữ lại
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/campaigns")
@CrossOrigin(origins = "*")
public class PartnerCampaignController {

    @Autowired
    private CampaignService campaignService;

    @Autowired
    private CampaignParticipantRepository participantRepo;

    @Autowired
    private CampaignRepository campaignRepository;


    @Autowired
    private PartnerRepository partnerRepository;

    @GetMapping
    public List<AdminCampaignListDto> getAll() {
        return campaignRepository.findAll().stream()
                .map(c -> new AdminCampaignListDto(
                        c.getCampaignId(),
                        c.getTitle(),
                        c.getLocationAddress(),
                        c.getStartDate(),
                        c.getEndDate(),
                        c.getMaxParticipants(),
                        c.getCurrentParticipants(),
                        c.getRewardPoints(),
                        c.getImageUrl(),
                        c.getQrCodeUrl(),
                        c.getPartner() != null ? c.getPartner().getCompanyName() : "Hệ thống EcoTrack"
                ))
                .toList();
    }

    @PostMapping(value = "/create", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<?> createCampaign(
            @RequestPart("data") String jsonData,
            @RequestPart(value = "image", required = false) MultipartFile image
    ) {
        try {
            // 1. Khởi tạo ObjectMapper và xử lý lỗi thời gian triệt để
            ObjectMapper objectMapper = new ObjectMapper();
            objectMapper.registerModule(new com.fasterxml.jackson.datatype.jsr310.JavaTimeModule());

            // Chuyển chuỗi JSON sang DTO
            CampaignRequestDto request = objectMapper.readValue(jsonData, CampaignRequestDto.class);

            // 2. Xử lý đường dẫn lưu ảnh đồng bộ với WebConfig
            // Chúng ta dùng đúng đường dẫn trong WebConfig (bỏ tiền tố "file:")
            String baseUploadPath = "D:/project_Capstone_1_full/Back_end/Ecotrack_backend/uploads/";

            if (image != null && !image.isEmpty()) {
                // Tạo tên file duy nhất
                String fileName = System.currentTimeMillis() + "_" + image.getOriginalFilename();

                // Đường dẫn thư mục con cho chiến dịch: .../uploads/campaigns/
                Path directoryPath = Paths.get(baseUploadPath, "campaigns");

                // Tự động tạo thư mục nếu chưa có
                if (!Files.exists(directoryPath)) {
                    Files.createDirectories(directoryPath);
                }

                // Lưu file vào ổ đĩa D:
                Path filePath = directoryPath.resolve(fileName);
                Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

                // Lưu đường dẫn tương đối vào DB để hiển thị được qua ResourceHandler (/uploads/...)
                request.setImageUrl("/uploads/campaigns/" + fileName);
            }

            // 3. Gọi Service lưu vào Database
            Campaign newCampaign = campaignService.createCampaign(request);

            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Tạo chiến dịch thành công!",
                    "data", newCampaign
            ));

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of(
                    "success", false,
                    "message", "Lỗi: " + e.getMessage()
            ));
        }
    }

    @PutMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<?> updateCampaign(
            @PathVariable Long id,
            @RequestBody CampaignRequestDto request
    ) {
        Campaign c = campaignRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Campaign not found"));

        c.setTitle(request.getTitle());
        c.setDescription(request.getDescription());
        c.setStartDate(request.getStartDate());
        c.setEndDate(request.getEndDate());
        c.setStartTime(request.getStartTime());
        c.setEndTime(request.getEndTime());
        c.setLocationAddress(request.getLocationAddress());
        c.setMaxParticipants(request.getMaxParticipants());
        c.setRewardPoints(request.getRewardPoints());
        c.setImageUrl(request.getImageUrl());

        campaignRepository.save(c);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @DeleteMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public ResponseEntity<?> delete(@PathVariable Long id) {

        if (participantRepo.countById_CampaignId(id) > 0) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", "Không thể xoá chiến dịch đã có người tham gia"
            ));
        }

        campaignRepository.deleteById(id);
        return ResponseEntity.ok(Map.of("success", true));
    }

    @GetMapping("/{id}")
    @PreAuthorize("hasAuthority('ROLE_ADMIN')")
    public AdminCampaignDetailDto getDetail(@PathVariable Long id) {
        Campaign c = campaignRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Campaign not found"));

        return new AdminCampaignDetailDto(
                c.getCampaignId(),
                c.getTitle(),
                c.getDescription(),
                c.getLocationAddress(),
                c.getStartDate(),
                c.getEndDate(),
                c.getMaxParticipants(),
                c.getRewardPoints(),
                c.getCurrentParticipants(),
                c.getImageUrl(),
                c.getQrCodeUrl()
        );
    }
    @GetMapping("/stats")
    public ResponseEntity<DashboardStatsDto> getDashboardStats() {
        DashboardStatsDto stats = new DashboardStatsDto(
                campaignRepository.countActiveCampaigns(),
                campaignRepository.countUpcomingCampaigns(),
                campaignRepository.countAllParticipants(),
                campaignRepository.sumTotalPoints() != null ? campaignRepository.sumTotalPoints() : 0
        );
        return ResponseEntity.ok(stats);
    }

}
