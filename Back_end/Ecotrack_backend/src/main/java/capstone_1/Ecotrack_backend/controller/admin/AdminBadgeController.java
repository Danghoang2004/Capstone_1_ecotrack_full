package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.request.AwardBadgeRequest;
import capstone_1.Ecotrack_backend.dto.request.BadgeRequest;
import capstone_1.Ecotrack_backend.model.Badge;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserBadge;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.service.BadgeService;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/api/admin/badges")
@RequiredArgsConstructor
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminBadgeController {

    private final BadgeService badgeService;
    private final UserRepository userRepository;
    private final CloudinaryService cloudinaryService;
    private final ObjectMapper objectMapper = new ObjectMapper();

    /**
     * Lấy danh sách tất cả huy hiệu
     */
    @GetMapping
    public ResponseEntity<List<Badge>> getAllBadges() {
        List<Badge> badges = badgeService.getAllBadges()
                .stream()
                .map(dto -> {
                    Badge badge = new Badge();
                    badge.setBadgeId(dto.getBadgeId());
                    badge.setBadgeName(dto.getBadgeName());
                    badge.setDescription(dto.getDescription());
                    badge.setIconUrl(dto.getIconUrl());
                    badge.setRequirement(dto.getRequirement());
                    badge.setPointsRequired(dto.getPointsRequired());
                    return badge;
                })
                .toList();
        return ResponseEntity.ok(badges);
    }

    /**
     * Lấy danh sách người dùng để award huy hiệu
     */
    @GetMapping("/users")
    public ResponseEntity<List<Map<String, Object>>> getUsersForAwarding() {
        List<User> users = userRepository.findAll();
        List<Map<String, Object>> userDtos = users.stream()
                .map(user -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", user.getId());
                    userMap.put("email", user.getEmail());
                    String fullName = user.getUserProfile() != null && user.getUserProfile().getFullName() != null
                            ? user.getUserProfile().getFullName()
                            : user.getUsername();
                    userMap.put("fullName", fullName);
                    return userMap;
                })
                .toList();
        return ResponseEntity.ok(userDtos);
    }

    /**
     * Tạo huy hiệu mới
     */
    @PostMapping
    public ResponseEntity<Map<String, Object>> createBadge(@RequestBody BadgeRequest request) {
        try {
            Badge badge = badgeService.createBadge(request);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Tạo huy hiệu thành công",
                    "data", badge
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Tạo huy hiệu mới bằng upload file ảnh
     */
    @PostMapping(value = "/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> createBadgeWithImage(
            @RequestPart("data") String jsonData,
            @RequestPart(value = "image", required = false) MultipartFile image) {
        try {
            BadgeRequest request = objectMapper.readValue(jsonData, BadgeRequest.class);
            if (image != null && !image.isEmpty()) {
                request.setIconUrl(cloudinaryService.uploadImage(image, "ecotrack/badges"));
            }
            Badge badge = badgeService.createBadge(request);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Tạo huy hiệu thành công",
                    "data", badge
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Cập nhật huy hiệu
     */
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updateBadge(@PathVariable Long id, @RequestBody BadgeRequest request) {
        try {
            Badge badge = badgeService.updateBadge(id, request);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Cập nhật huy hiệu thành công",
                    "data", badge
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Cập nhật huy hiệu bằng upload file ảnh
     */
    @PutMapping(value = "/{id}/upload", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<Map<String, Object>> updateBadgeWithImage(
            @PathVariable Long id,
            @RequestPart("data") String jsonData,
            @RequestPart(value = "image", required = false) MultipartFile image) {
        try {
            BadgeRequest request = objectMapper.readValue(jsonData, BadgeRequest.class);
            if (image != null && !image.isEmpty()) {
                request.setIconUrl(cloudinaryService.uploadImage(image, "ecotrack/badges"));
            }
            Badge badge = badgeService.updateBadge(id, request);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Cập nhật huy hiệu thành công",
                    "data", badge
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Xóa huy hiệu
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Map<String, Object>> deleteBadge(@PathVariable Long id) {
        try {
            badgeService.deleteBadge(id);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Xóa huy hiệu thành công"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Trao huy hiệu cho người dùng
     */
    @PostMapping("/award")
    public ResponseEntity<Map<String, Object>> awardBadge(@RequestBody AwardBadgeRequest request) {
        try {
            UserBadge userBadge = badgeService.awardBadgeToUser(request);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Trao huy hiệu thành công",
                    "data", Map.of(
                            "userId", userBadge.getId().getUserId(),
                            "badgeId", userBadge.getId().getBadgeId(),
                            "awardedAt", userBadge.getAwardedAt()
                    )
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }

    /**
     * Thu hồi huy hiệu từ người dùng
     */
    @DeleteMapping("/{badgeId}/users/{userId}")
    public ResponseEntity<Map<String, Object>> removeBadgeFromUser(
            @PathVariable Long badgeId,
            @PathVariable Long userId
    ) {
        try {
            badgeService.removeBadgeFromUser(userId, badgeId);
            return ResponseEntity.ok(Map.of(
                    "success", true,
                    "message", "Thu hồi huy hiệu thành công"
            ));
        } catch (Exception e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "success", false,
                    "message", e.getMessage()
            ));
        }
    }
}
