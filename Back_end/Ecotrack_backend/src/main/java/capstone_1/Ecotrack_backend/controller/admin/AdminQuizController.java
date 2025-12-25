package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.model.Quiz;
import capstone_1.Ecotrack_backend.repository.QuizQuestionRepository;
import capstone_1.Ecotrack_backend.repository.QuizRepository;
import capstone_1.Ecotrack_backend.service.QuizImportService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.Map;

@RestController
@RequestMapping("/api/admin/quizzes")
public class AdminQuizController {
    @Autowired
    private QuizImportService importService;

    @Autowired
    private QuizRepository quizRepository;

    @Autowired
    private QuizQuestionRepository questionRepository;

    @PostMapping("/{quizId}/import")
    public ResponseEntity<?> importQuestions(
            @PathVariable Long quizId,
            @RequestParam("file") MultipartFile file) {
        try {
            importService.importQuestionsFromExcel(file, quizId);
            return ResponseEntity.ok(Map.of("message", "Import thành công!"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Lỗi: " + e.getMessage());
        }
    }
    @PostMapping("/create-with-import")
    public ResponseEntity<?> createWithImport(
            @RequestParam("title") String title,
            @RequestParam("pointsReward") Integer pointsReward,
            @RequestParam("file") MultipartFile file) {
        try {
            Quiz createdQuiz = importService.createQuizWithQuestions(title, pointsReward, file);
            return ResponseEntity.ok(Map.of(
                    "message", "Đã tạo bộ đề mới và import câu hỏi thành công!",
                    "quizId", createdQuiz.getId(),
                    "title", createdQuiz.getTitle()
            ));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Lỗi: " + e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<?> getAllQuizzes() {
        return ResponseEntity.ok(quizRepository.findAll());
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteQuiz(@PathVariable Long id) {
        try {
            // Gọi hàm xóa an toàn từ Service
            importService.deleteQuizAndRelatedData(id);
            return ResponseEntity.ok(Map.of("message", "Đã xóa bộ đề và toàn bộ dữ liệu liên quan thành công"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Lỗi khi xóa bộ đề: " + e.getMessage());
        }
    }

    @GetMapping("/{quizId}/questions")
    public ResponseEntity<?> getQuestions(@PathVariable Long quizId) {
        return ResponseEntity.ok(questionRepository.findByQuiz_Id(quizId));
    }
}