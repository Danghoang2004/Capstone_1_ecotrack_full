package capstone_1.Ecotrack_backend.controller.environment;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.request.environment.EnvironmentTaskCompletionRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentCleanupTaskResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentMyTeamInfoResponse;
import capstone_1.Ecotrack_backend.service.environment.EnvironmentCleanupService;
import capstone_1.Ecotrack_backend.service.environment.EnvironmentTeamManagementService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/environment/tasks")
@PreAuthorize("hasAuthority('ROLE_ENVIRONMENT')")
public class EnvironmentCleanupController {

    private final EnvironmentCleanupService environmentCleanupService;
    private final EnvironmentTeamManagementService environmentTeamManagementService;
    private final CloudinaryService cloudinaryService;

    public EnvironmentCleanupController(EnvironmentCleanupService environmentCleanupService,
            EnvironmentTeamManagementService environmentTeamManagementService,
            CloudinaryService cloudinaryService) {
        this.environmentCleanupService = environmentCleanupService;
        this.environmentTeamManagementService = environmentTeamManagementService;
        this.cloudinaryService = cloudinaryService;
    }

    @GetMapping("/my")
    public List<EnvironmentCleanupTaskResponse> getMyTasks(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentCleanupService.getMyTasks(userId);
    }

    @GetMapping("/my-team")
    public EnvironmentMyTeamInfoResponse getMyTeamInfo(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentTeamManagementService.getMyTeamInfo(userId);
    }

    @PutMapping("/{taskId}/complete")
    public EnvironmentCleanupTaskResponse completeTask(@PathVariable Long taskId,
            @Valid @RequestBody EnvironmentTaskCompletionRequest body,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentCleanupService.submitCleanupEvidence(taskId, userId, body);
    }

    @PostMapping("/upload-image")
    public ResponseEntity<Map<String, String>> uploadImage(@RequestParam("image") MultipartFile image) {
        try {
            if (image == null || image.isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("message", "Ảnh không hợp lệ"));
            }

            String imageUrl = cloudinaryService.uploadImage(image, "ecotrack/environment-tasks");
            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("message", "Upload ảnh thành công");
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("message", "Không thể upload ảnh"));
        }
    }
}
