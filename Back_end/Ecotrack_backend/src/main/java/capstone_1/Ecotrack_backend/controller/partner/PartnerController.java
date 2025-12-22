package capstone_1.Ecotrack_backend.controller.partner;


import capstone_1.Ecotrack_backend.dto.request.UpdatePartnerSettingsRequest;
import capstone_1.Ecotrack_backend.dto.response.PartnerSettingsResponse;
import capstone_1.Ecotrack_backend.service.PartnerService;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/partner/settings")
public class PartnerController {

    private final PartnerService partnerService;

    public PartnerController(PartnerService partnerService) {
        this.partnerService = partnerService;
    }

    @GetMapping
    public PartnerSettingsResponse getSettings(Authentication authentication) {

        System.out.println("JWT SUBJECT = " + authentication.getName());

        return partnerService.getPartnerSettingsBySubject(authentication.getName());
    }


    @PutMapping
    public ResponseEntity<?> updateSettings(
            Authentication authentication,
            @RequestBody UpdatePartnerSettingsRequest request
    ) {
        String username = authentication.getName();
        partnerService.updatePartnerSettingsByUsername(username, request);
        return ResponseEntity.ok().build();
    }
}

