package capstone_1.Ecotrack_backend.service;


import capstone_1.Ecotrack_backend.dto.request.UpdatePartnerSettingsRequest;
import capstone_1.Ecotrack_backend.dto.response.PartnerSettingsResponse;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserProfile;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.repository.UserProfileRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
@Transactional
public class PartnerServiceImpl implements PartnerService {

    private final PartnerRepository partnerRepository;
    private final UserRepository userRepository;
    private final UserProfileRepository userProfileRepository;

    public PartnerServiceImpl(
            PartnerRepository partnerRepository,
            UserRepository userRepository,
            UserProfileRepository userProfileRepository
    ) {
        this.partnerRepository = partnerRepository;
        this.userRepository = userRepository;
        this.userProfileRepository = userProfileRepository;
    }

    @Override
    public PartnerSettingsResponse getPartnerSettings(Long userId) {

        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Partner not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserProfile profile = userProfileRepository.findByUser_Id(userId)
                .orElse(null);

        return new PartnerSettingsResponse(
                partner.getPartnerId(),
                partner.getCompanyName(),
                user.getEmail(),
                profile != null ? profile.getPhone_number() : null,
                partner.getWebsite(),
                partner.getLogoUrl()
        );
    }

    @Override
    public void updatePartnerSettings(Long userId, UpdatePartnerSettingsRequest request) {

        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Partner not found"));

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        UserProfile profile = userProfileRepository
                .findByUser_Id(userId)
                .orElseGet(() -> {
                    UserProfile p = new UserProfile();
                    p.setUser(user);
                    return p;
                });

        partner.setCompanyName(request.getCompanyName());
        partner.setWebsite(request.getWebsite());
        partner.setLogoUrl(request.getLogoUrl());

        user.setEmail(request.getEmail());

        profile.setPhone_number(request.getPhoneNumber());

        partnerRepository.save(partner);
        userRepository.save(user);
        userProfileRepository.save(profile);
    }

    @Override
    public PartnerSettingsResponse getPartnerSettingsByUsername(String email) {

        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return getPartnerSettings(user.getId());
    }

    @Override
    public void updatePartnerSettingsByUsername(
            String username,
            UpdatePartnerSettingsRequest request
    ) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));

        updatePartnerSettings(user.getId(), request);
    }

    @Override
    public PartnerSettingsResponse getPartnerSettingsBySubject(String subject) {

        User user = userRepository.findByEmail(subject)
                .orElseGet(() -> userRepository.findByUsername(subject)
                        .orElseThrow(() -> new RuntimeException("User not found")));

        return getPartnerSettings(user.getId());
    }

}