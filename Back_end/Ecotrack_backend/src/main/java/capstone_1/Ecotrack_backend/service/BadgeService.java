package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.BadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserBadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.dto.response.BadgeProgressResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class BadgeService {

    private final BadgeRepository badgeRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final UserRepository userRepository;
    private final UserPointsRepository userPointsRepository;

    public List<BadgeResponse> getAllBadges() {
        return badgeRepository.findAllByOrderByBadgeIdAsc()
                .stream()
                .map(this::toBadgeResponse)
                .collect(Collectors.toList());
    }

    public List<BadgeResponse> getAllBadgesWithProgress(Long userId) {
        if (userId == null || !userRepository.existsById(userId)) {
            throw new RuntimeException("Không tìm thấy người dùng");
        }

        Set<Long> claimedBadgeIds = new HashSet<>();
        userBadgeRepository.findByUserId(userId)
                .forEach(ub -> claimedBadgeIds.add(ub.getBadge().getBadgeId()));

        return badgeRepository.findAllByOrderByBadgeIdAsc()
                .stream()
                .map(badge -> {
                    if (claimedBadgeIds.contains(badge.getBadgeId())) {
                        UserBadge userBadge = userBadgeRepository.findByUserId(userId)
                                .stream()
                                .filter(ub -> ub.getBadge().getBadgeId().equals(badge.getBadgeId()))
                                .findFirst()
                                .orElse(null);
                        return toBadgeResponse(userBadge);
                    } else {
                        return toBadgeResponse(badge);
                    }
                })
                .filter(response -> response != null)
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

    public BadgeProgressResponse getBadgeProgressWithCurrentPoints(Long userId) {
        if (userId == null || !userRepository.existsById(userId)) {
            throw new RuntimeException("Không tìm thấy người dùng");
        }

        UserPoints userPoints = userPointsRepository.findById(userId).orElse(null);
        Integer currentPoints = (userPoints != null) ? userPoints.getPoints() : 0;

        List<BadgeResponse> badges = getAllBadgesWithProgress(userId);

        return new BadgeProgressResponse(currentPoints, badges);
    }

    private BadgeResponse toBadgeResponse(Badge badge) {
        BadgeResponse response = new BadgeResponse();
        response.setBadgeId(badge.getBadgeId());
        response.setBadgeName(badge.getBadgeName());
        response.setIconUrl(badge.getIconUrl());
        response.setDescription(badge.getDescription());
        response.setRequirement(badge.getRequirement());
        response.setPointsRequired(badge.getPointsRequired());
        response.setAwardedAt(null);
        response.setIsClaimed(false);
        return response;
    }

    private BadgeResponse toBadgeResponse(UserBadge userBadge) {
        if (userBadge == null) {
            return null;
        }
        Badge badge = userBadge.getBadge();
        BadgeResponse response = new BadgeResponse();
        response.setBadgeId(badge.getBadgeId());
        response.setBadgeName(badge.getBadgeName());
        response.setIconUrl(badge.getIconUrl());
        response.setDescription(badge.getDescription());
        response.setRequirement(badge.getRequirement());
        response.setPointsRequired(badge.getPointsRequired());
        response.setAwardedAt(userBadge.getAwardedAt() != null ? userBadge.getAwardedAt().toString() : null);
        response.setIsClaimed(true);
        return response;
    }
}
