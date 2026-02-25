package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.*;
import capstone_1.Ecotrack_backend.dto.request.*;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.service.QuizService;
import capstone_1.Ecotrack_backend.model.User;
import org.springframework.security.core.Authentication;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/quizzes")
@RequiredArgsConstructor
@CrossOrigin(origins = "*", methods = { RequestMethod.GET, RequestMethod.POST, RequestMethod.OPTIONS })
public class QuizController {

    private final QuizService service;
    private final UserRepository userRepo;

    @GetMapping("/{quizId}")
    public QuizDetailDto getQuiz(@PathVariable("quizId") Long quizId) {
        return service.getQuiz(quizId);
    }

    @PostMapping("/{quizId}/submit")
    public SubmitResponse submit(
            @PathVariable Long quizId,
            @RequestBody SubmitRequest request,
            Authentication authentication) {
        String email = authentication.getName();

        User user = userRepo.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));

        return service.submit(quizId, user.getId(), request);
    }

    @GetMapping("/summary")
    public QuizSummaryDto getSummary(Authentication authentication) {
        String email = authentication.getName();
        User user = userRepo.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return service.getMyQuizSummary(user.getId());
    }
}
