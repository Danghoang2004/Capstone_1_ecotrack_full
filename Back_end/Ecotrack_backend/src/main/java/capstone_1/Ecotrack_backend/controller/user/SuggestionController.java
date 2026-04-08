package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.SuggestionResponseDTO;
import capstone_1.Ecotrack_backend.service.RecyclingSuggestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/user/suggestions")
@CrossOrigin(origins = "*")
public class SuggestionController {

    @Autowired
    private RecyclingSuggestionService suggestionService;

    // 1. API cũ: Lấy gợi ý trực tiếp bằng tên Category (VD: /NHUA)
    @GetMapping("/{category}")
    public ResponseEntity<List<SuggestionResponseDTO>> getSuggestions(@PathVariable("category") String category) {
        List<SuggestionResponseDTO> suggestions = suggestionService.getSuggestionsByCategory(category);
        
        if (suggestions.isEmpty()) {
            return ResponseEntity.noContent().build(); 
        }
        return ResponseEntity.ok(suggestions); 
    }

    // 2. API MỚI (CẦN THÊM VÀO): Lấy gợi ý bằng ID của WasteReport sau khi AI đã lưu
    @GetMapping("/report/{reportId}")
    public ResponseEntity<List<SuggestionResponseDTO>> getSuggestionsByReport(@PathVariable("reportId") Long reportId) {
        List<SuggestionResponseDTO> suggestions = suggestionService.getSuggestionsByReportId(reportId);
        
        if (suggestions.isEmpty()) {
            return ResponseEntity.noContent().build(); 
        }
        
        return ResponseEntity.ok(suggestions); 
    }
}