package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.*;
import capstone_1.Ecotrack_backend.dto.request.*;
import capstone_1.Ecotrack_backend.service.QuizService;
import capstone_1.Ecotrack_backend.model.User;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/quizzes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", methods = { RequestMethod.GET, RequestMethod.POST, RequestMethod.OPTIONS })
public class QuizController {

    private final QuizService service;

    @GetMapping("/{quizId}")
    public QuizDetailDto getQuiz(@PathVariable("quizId") Long quizId) {
        return service.getQuiz(quizId);
    }

    @PostMapping("/{quizId}/submit")
    public SubmitResponse submit(
            @PathVariable("quizId") Long quizId,
            @AuthenticationPrincipal User user, // 👈 lấy thẳng entity User từ JWT
            @RequestBody SubmitRequest req) {
        Long userId = user.getId(); // 👈 userId thật từ DB
        return service.submit(quizId, userId, req);
    }

    @GetMapping("/summary")
    public QuizSummaryDto getSummary(@AuthenticationPrincipal User user) {
        Long userId = user.getId(); // 👈 lấy id từ JWT
        return service.getMyQuizSummary(userId);
    }
}
