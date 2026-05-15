package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.dto.request.BadgeRequest;
import capstone_1.Ecotrack_backend.dto.request.AwardBadgeRequest;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.model.UserBadgeId;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.BadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserBadgeRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.dto.response.BadgeProgressResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
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

    // ========== ADMIN BADGE MANAGEMENT METHODS ==========

    public Badge createBadge(BadgeRequest request) {
        if (request.getBadgeName() == null || request.getBadgeName().isBlank()) {
            throw new RuntimeException("Tên huy hiệu không được để trống");
        }

        Badge badge = new Badge();
        badge.setBadgeName(request.getBadgeName());
        badge.setDescription(request.getDescription());
        badge.setIconUrl(request.getIconUrl());
        badge.setRequirement(request.getRequirement());
        badge.setPointsRequired(request.getPointsRequired() != null ? request.getPointsRequired() : 0);

        return badgeRepository.save(badge);
    }

    public Badge updateBadge(Long badgeId, BadgeRequest request) {
        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy huy hiệu với ID: " + badgeId));

        if (request.getBadgeName() != null && !request.getBadgeName().isBlank()) {
            badge.setBadgeName(request.getBadgeName());
        }
        if (request.getDescription() != null) {
            badge.setDescription(request.getDescription());
        }
        if (request.getIconUrl() != null) {
            badge.setIconUrl(request.getIconUrl());
        }
        if (request.getRequirement() != null) {
            badge.setRequirement(request.getRequirement());
        }
        if (request.getPointsRequired() != null) {
            badge.setPointsRequired(request.getPointsRequired());
        }

        return badgeRepository.save(badge);
    }

    public void deleteBadge(Long badgeId) {
        Badge badge = badgeRepository.findById(badgeId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy huy hiệu với ID: " + badgeId));

        // Xóa tất cả UserBadge liên quan
        userBadgeRepository.deleteByBadgeId(badgeId);

        // Xóa badge
        badgeRepository.delete(badge);
    }

    public UserBadge awardBadgeToUser(AwardBadgeRequest request) {
        if (request.getUserId() == null || request.getBadgeId() == null) {
            throw new RuntimeException("userId và badgeId không được để trống");
        }

        // Kiểm tra user tồn tại
        if (!userRepository.existsById(request.getUserId())) {
            throw new RuntimeException("Không tìm thấy người dùng với ID: " + request.getUserId());
        }

        // Kiểm tra badge tồn tại
        Badge badge = badgeRepository.findById(request.getBadgeId())
                .orElseThrow(() -> new RuntimeException("Không tìm thấy huy hiệu với ID: " + request.getBadgeId()));

        // Kiểm tra user đã có badge này chưa
        UserBadgeId id = new UserBadgeId(request.getUserId(), request.getBadgeId());
        if (userBadgeRepository.existsById(id)) {
            throw new RuntimeException("Người dùng đã có huy hiệu này rồi");
        }

        // Tạo UserBadge mới
        UserBadge userBadge = new UserBadge();
        userBadge.setId(id);
        userBadge.setUser(userRepository.getReferenceById(request.getUserId()));
        userBadge.setBadge(badge);
        userBadge.setAwardedAt(LocalDateTime.now());

        return userBadgeRepository.save(userBadge);
    }

    public void removeBadgeFromUser(Long userId, Long badgeId) {
        UserBadgeId id = new UserBadgeId(userId, badgeId);
        if (!userBadgeRepository.existsById(id)) {
            throw new RuntimeException("Người dùng không có huy hiệu này");
        }
        userBadgeRepository.deleteById(id);
    }
}
