package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.RecyclingSuggestionDto;
import capstone_1.Ecotrack_backend.service.RecyclingSuggestionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/public/recycling-suggestions")
@CrossOrigin(origins = "*", maxAge = 3600)
public class RecyclingSuggestionController {

    @Autowired
    private RecyclingSuggestionService recyclingSuggestionService;

    @GetMapping
    public ResponseEntity<List<RecyclingSuggestionDto>> getSuggestionsByCategory(
            @RequestParam(value = "category", required = false) String category) {

        if (category != null && !category.isEmpty()) {
            List<RecyclingSuggestionDto> suggestions = recyclingSuggestionService.getSuggestionsByCategory(category);
            return ResponseEntity.ok(suggestions);
        } else {

            List<RecyclingSuggestionDto> suggestions = recyclingSuggestionService.getAllActiveSuggestions();
            return ResponseEntity.ok(suggestions);
        }
    }

    @GetMapping("/all")
    public ResponseEntity<List<RecyclingSuggestionDto>> getAllSuggestions() {
        List<RecyclingSuggestionDto> suggestions = recyclingSuggestionService.getAllActiveSuggestions();
        return ResponseEntity.ok(suggestions);
    }

    @GetMapping("/category/{category}")
    public ResponseEntity<List<RecyclingSuggestionDto>> getSuggestionsByWasteCategory(
            @PathVariable String category) {
        List<RecyclingSuggestionDto> suggestions = recyclingSuggestionService.getSuggestionsByCategory(category);
        return ResponseEntity.ok(suggestions);
    }
}
