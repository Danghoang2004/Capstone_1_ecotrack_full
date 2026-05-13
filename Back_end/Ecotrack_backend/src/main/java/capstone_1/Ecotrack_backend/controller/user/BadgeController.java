package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.ApiBadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeResponse;
import capstone_1.Ecotrack_backend.dto.response.BadgeProgressResponse;
import capstone_1.Ecotrack_backend.service.BadgeService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/user/badges")
@RequiredArgsConstructor
public class BadgeController {

    private final BadgeService badgeService;

    @GetMapping("/all")
    public ResponseEntity<ApiBadgeResponse<List<BadgeResponse>>> getAllBadges() {
        List<BadgeResponse> data = badgeService.getAllBadges();
        return ResponseEntity.ok(ApiBadgeResponse.success("Lấy danh sách huy hiệu thành công", data));
    }

    @GetMapping("/my")
    public ResponseEntity<ApiBadgeResponse<List<BadgeResponse>>> getMyEarnedBadges(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).body(ApiBadgeResponse.error("Unauthorized"));
        }

        try {
            List<BadgeResponse> data = badgeService.getUserEarnedBadges(userId);
            return ResponseEntity.ok(ApiBadgeResponse.success("Lấy danh sách huy hiệu đã đạt thành công", data));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiBadgeResponse.error(e.getMessage()));
        }
    }

    @GetMapping("/progress")
    public ResponseEntity<ApiBadgeResponse<BadgeProgressResponse>> getBadgeProgress(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(401).body(ApiBadgeResponse.error("Unauthorized"));
        }

        try {
            BadgeProgressResponse data = badgeService.getBadgeProgressWithCurrentPoints(userId);
            return ResponseEntity.ok(ApiBadgeResponse.success("Lấy tiến độ huy hiệu thành công", data));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(ApiBadgeResponse.error(e.getMessage()));
        }
    }
}
