package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.request.RecycleSuggestionQueryRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.dto.response.RecycleSuggestionDetailDto;
import capstone_1.Ecotrack_backend.dto.response.RecycleSuggestionListItemDto;
import capstone_1.Ecotrack_backend.service.RecycleSuggestionService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.CrossOrigin;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/user/ai/recycle-suggestions")
@CrossOrigin
public class RecycleSuggestionController {

    private static final Logger log = LoggerFactory.getLogger(RecycleSuggestionController.class);

    private final RecycleSuggestionService recycleSuggestionService;

    public RecycleSuggestionController(RecycleSuggestionService recycleSuggestionService) {
        this.recycleSuggestionService = recycleSuggestionService;
    }

    @PostMapping("/query")
    public ResponseEntity<ApiResponse<List<RecycleSuggestionListItemDto>>> querySuggestions(
            HttpServletRequest request,
            @Valid @RequestBody RecycleSuggestionQueryRequest queryRequest) {
        try {
            Object userId = request.getAttribute("userId");
            if (userId == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.error("RECYCLE_SUGGESTION_UNAUTHORIZED",
                                "Không xác định được người dùng hiện tại."));
            }

            List<RecycleSuggestionListItemDto> suggestions = recycleSuggestionService
                    .findSuggestionsByWasteTypes(queryRequest.getWasteTypes());

            return ResponseEntity.ok(ApiResponse.success(
                    "RECYCLE_SUGGESTION_LIST_SUCCESS",
                    "Lấy danh sách gợi ý tái chế thành công.",
                    suggestions));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("RECYCLE_SUGGESTION_BAD_REQUEST", ex.getMessage()));
        } catch (Exception ex) {
            log.error("Query recycle suggestions failed", ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("RECYCLE_SUGGESTION_INTERNAL_ERROR", "Lỗi hệ thống khi truy vấn gợi ý tái chế."));
        }
    }

    @GetMapping("/{suggestionId}")
    public ResponseEntity<ApiResponse<RecycleSuggestionDetailDto>> getSuggestionDetail(
            HttpServletRequest request,
            @PathVariable Long suggestionId) {
        try {
            Object userId = request.getAttribute("userId");
            if (userId == null) {
                return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(
                        ApiResponse.error("RECYCLE_SUGGESTION_UNAUTHORIZED",
                                "Không xác định được người dùng hiện tại."));
            }

            RecycleSuggestionDetailDto detail = recycleSuggestionService.getSuggestionDetail(suggestionId);
            return ResponseEntity.ok(ApiResponse.success(
                    "RECYCLE_SUGGESTION_DETAIL_SUCCESS",
                    "Lấy chi tiết gợi ý tái chế thành công.",
                    detail));
        } catch (IllegalArgumentException ex) {
            return ResponseEntity.badRequest().body(
                    ApiResponse.error("RECYCLE_SUGGESTION_BAD_REQUEST", ex.getMessage()));
        } catch (Exception ex) {
            log.error("Get recycle suggestion detail failed, suggestionId={}", suggestionId, ex);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(
                    ApiResponse.error("RECYCLE_SUGGESTION_INTERNAL_ERROR",
                            "Lỗi hệ thống khi lấy chi tiết gợi ý tái chế."));
        }
    }
}
