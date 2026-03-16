package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.repository.BadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserBadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BadgeService {

    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final UserRepository userRepository;

    public List<BadgeResponse> getAllBadges() {
        return badgeRepository.findAllByOrderByBadgeIdAsc()
                .stream()
                .map(this::toBadgeResponse)
                .collect(Collectors.toList());
    }

    public List<BadgeResponse> getUserEarnedBadges(Long userId) {
        if (userId == null || !userRepository.existsById(userId)) {
            throw new RuntimeException("Không tìm thấy người dùng");
        }

        return userBadgeRepository.findByUserId(userId)
                .stream()
                .map(this::toBadgeResponse)
                .collect(Collectors.toList());
    }

    private BadgeResponse toBadgeResponse(Badge badge) {
        BadgeResponse response = new BadgeResponse();
        response.setBadgeId(badge.getBadgeId());
        response.setBadgeName(badge.getBadgeName());
        response.setIconUrl(badge.getIconUrl());
        response.setDescription(badge.getDescription());
        response.setRequirement(badge.getRequirement());
        response.setAwardedAt(null);
        return response;
    }

    private BadgeResponse toBadgeResponse(UserBadge userBadge) {
        Badge badge = userBadge.getBadge();
        BadgeResponse response = new BadgeResponse();
        response.setBadgeId(badge.getBadgeId());
        response.setBadgeName(badge.getBadgeName());
        response.setIconUrl(badge.getIconUrl());
        response.setDescription(badge.getDescription());
        response.setRequirement(badge.getRequirement());
        response.setAwardedAt(userBadge.getAwardedAt() != null ? userBadge.getAwardedAt().toString() : null);
        return response;
    }
}
