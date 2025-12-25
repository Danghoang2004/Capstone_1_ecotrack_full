package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.UpdatePartnerSettingsRequest;
import capstone_1.Ecotrack_backend.dto.response.PartnerSettingsResponse;

public interface PartnerService {
    PartnerSettingsResponse getPartnerSettings(Long userId);

    void updatePartnerSettings(Long userId, UpdatePartnerSettingsRequest request);

    PartnerSettingsResponse getPartnerSettingsByUsername(String username);

    void updatePartnerSettingsByUsername(
            String username,
            UpdatePartnerSettingsRequest request
    );

    PartnerSettingsResponse getPartnerSettingsBySubject(String subject);
}
