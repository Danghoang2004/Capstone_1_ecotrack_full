package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.AiWasteClassificationResultDto;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.service.AiWasteClassificationProxyService;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/api/user/ai")
@CrossOrigin
public class AiWasteClassificationController {

    private final AiWasteClassificationProxyService aiWasteClassificationProxyService;

    public AiWasteClassificationController(AiWasteClassificationProxyService aiWasteClassificationProxyService) {
        this.aiWasteClassificationProxyService = aiWasteClassificationProxyService;
    }

    @PostMapping(value = "/classify-waste", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public ResponseEntity<ApiResponse<AiWasteClassificationResultDto>> classifyWaste(
            @RequestParam("image") MultipartFile image) {
        try {
            if (image == null || image.isEmpty()) {
                return ResponseEntity.badRequest().body(
                        ApiResponse.error("AI_CLASSIFY_BAD_REQUEST", "Vui lòng tải lên ảnh cần phân loại."));
            }

            AiWasteClassificationResultDto result = aiWasteClassificationProxyService.classifyWaste(image);

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
}
