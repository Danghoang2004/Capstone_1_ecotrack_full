package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.response.AiWasteClassificationResultDto;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.dto.response.ClassificationHistoryDetailDto;
import capstone_1.Ecotrack_backend.dto.response.ClassificationHistoryListItemDto;
import capstone_1.Ecotrack_backend.service.AiWasteClassificationHistoryService;
import capstone_1.Ecotrack_backend.service.AiWasteClassificationProxyService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/user/ai")
@CrossOrigin
public class AiWasteClassificationController {

    private final AiWasteClassificationProxyService aiWasteClassificationProxyService;
    private final AiWasteClassificationHistoryService aiWasteClassificationHistoryService;
    private final CloudinaryService cloudinaryService;

    public AiWasteClassificationController(
            AiWasteClassificationProxyService aiWasteClassificationProxyService,
            AiWasteClassificationHistoryService aiWasteClassificationHistoryService,
            CloudinaryService cloudinaryService) {
        this.aiWasteClassificationProxyService = aiWasteClassificationProxyService;
        this.aiWasteClassificationHistoryService = aiWasteClassificationHistoryService;
        this.cloudinaryService = cloudinaryService;
    }

    @PostMapping(value = "/classify-waste", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<AiWasteClassificationResultDto>> classifyWaste(
            HttpServletRequest request,
            @RequestParam("image") MultipartFile image) {
        try {
            if (image == null || image.isEmpty()) {
                return ResponseEntity.badRequest().body(
                        ApiResponse.error("AI_CLASSIFY_BAD_REQUEST", "Vui lòng tải lên ảnh cần phân loại."));
            }

            Object userIdAttribute = request.getAttribute("userId");
            if (userIdAttribute == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.error("AI_CLASSIFY_UNAUTHORIZED", "Không xác định được người dùng hiện tại."));
            }

            Long userId = Long.valueOf(userIdAttribute.toString());
            String originalImageUrl = cloudinaryService.uploadImage(image, "ecotrack/ai-classification");

            AiWasteClassificationResultDto result = aiWasteClassificationProxyService.classifyWaste(image);
            aiWasteClassificationHistoryService.saveResult(userId, originalImageUrl, result);

            return ResponseEntity.ok(
                    ApiResponse.success(
                            "AI_CLASSIFY_SUCCESS",
                            "Phân loại rác thành công.",
                            result));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("AI_CLASSIFY_BAD_REQUEST", ex.getMessage()));
        } catch (IllegalStateException ex) {
            return ResponseEntity.status(HttpStatus.BAD_GATEWAY).body(
                    ApiResponse.error("AI_CLASSIFY_AI_UNAVAILABLE", ex.getMessage()));
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("AI_CLASSIFY_INTERNAL_ERROR", "Lỗi hệ thống khi phân loại rác."));
        }
    }

    @GetMapping("/classification-history")
    public ResponseEntity<ApiResponse<List<ClassificationHistoryListItemDto>>> getClassificationHistory(
            HttpServletRequest request) {
        try {
            Object userIdAttribute = request.getAttribute("userId");
            if (userIdAttribute == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.error("AI_HISTORY_UNAUTHORIZED", "Không xác định được người dùng hiện tại."));
            }

            Long userId = Long.valueOf(userIdAttribute.toString());
            List<ClassificationHistoryListItemDto> history = aiWasteClassificationHistoryService
                    .getClassificationHistory(userId);

            return ResponseEntity.ok(
                    ApiResponse.success(
                            "AI_HISTORY_LIST_SUCCESS",
                            "Lấy lịch sử phân loại thành công.",
                            history));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("AI_HISTORY_BAD_REQUEST", ex.getMessage()));
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("AI_HISTORY_INTERNAL_ERROR", "Lỗi hệ thống khi lấy lịch sử phân loại."));
        }
    }

    @GetMapping("/classification-history/{historyId}")
    public ResponseEntity<ApiResponse<ClassificationHistoryDetailDto>> getHistoryDetail(
            HttpServletRequest request,
            @PathVariable Long historyId) {
        try {
            if (historyId == null) {
                return ResponseEntity.badRequest().body(
                        ApiResponse.error("AI_HISTORY_BAD_REQUEST", "ID lịch sử không được để trống."));
            }

            Object userIdAttribute = request.getAttribute("userId");
            if (userIdAttribute == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.error("AI_HISTORY_UNAUTHORIZED", "Không xác định được người dùng hiện tại."));
            }

            ClassificationHistoryDetailDto detail = aiWasteClassificationHistoryService.getHistoryDetail(historyId);

            return ResponseEntity.ok(
                    ApiResponse.success(
                            "AI_HISTORY_DETAIL_SUCCESS",
                            "Lấy chi tiết lịch sử phân loại thành công.",
                            detail));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("AI_HISTORY_BAD_REQUEST", ex.getMessage()));
        } catch (Exception ex) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("AI_HISTORY_INTERNAL_ERROR", "Lỗi hệ thống khi lấy chi tiết lịch sử phân loại."));
        }
    }
}
