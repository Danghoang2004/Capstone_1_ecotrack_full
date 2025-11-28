package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.*;
import capstone_1.Ecotrack_backend.dto.request.*;
import capstone_1.Ecotrack_backend.model.UserQuizAttempt;
import capstone_1.Ecotrack_backend.repository.QuizQuestionRepository;
import capstone_1.Ecotrack_backend.repository.QuizRepository;
import capstone_1.Ecotrack_backend.repository.UserQuizAttemptRepository;


import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;

@Service
@RequiredArgsConstructor
public class QuizService {

    private final QuizRepository quizRepo;
    private final QuizQuestionRepository questionRepo;
    private final UserQuizAttemptRepository attemptRepo;

    // =========================================================
    // ⭐ LẤY QUIZ – TRẢ VỀ NGẪU NHIÊN 2 CÂU + ĐÁP ÁN ĐÚNG (correctKey)
    // =========================================================
    public QuizDetailDto getQuiz(Long quizId) {
    var quiz = quizRepo.findById(quizId).orElseThrow();

    // Lấy toàn bộ câu hỏi trong quiz (50 câu)
    var questions = new ArrayList<>(questionRepo.findByQuiz_Id(quizId));

    // ⭐ Xáo trộn ngẫu nhiên
    Collections.shuffle(questions);

    // ⭐ Lấy đúng 20 câu
    var selected = questions.stream().limit(20).toList();

    // Map sang DTO
    var dtoQuestions = selected.stream()
            .map(q -> new QuizDetailDto.Question(
                    q.getId(),
                    q.getQuestionText(),
                    q.getCorrectOption() != null ? q.getCorrectOption().name() : null, // gửi correctKey
                    List.of(
                            new QuizDetailDto.Option("A", q.getOptionA()),
                            new QuizDetailDto.Option("B", q.getOptionB()),
                            new QuizDetailDto.Option("C", q.getOptionC()),
                            new QuizDetailDto.Option("D", q.getOptionD())
                    )
            ))
            .toList();

    return new QuizDetailDto(
            quiz.getId(),
            quiz.getTitle(),
            quiz.getPointsReward(),
            dtoQuestions
    );
}


    // =========================================================
    // ⭐ CHẤM ĐIỂM QUIZ
    // =========================================================
   public SubmitResponse submit(Long quizId,Long userId, SubmitRequest req) {

    int total = req.answers().size();
    int correct = 0;

    List<Boolean> correctnessList = new ArrayList<>();

    for (var ans : req.answers()) {
        // Lấy đúng câu mà FE gửi về
        var q = questionRepo.findById(ans.questionId()).orElse(null);

        if (q == null) {
            correctnessList.add(false);
            continue;
        }

        boolean isCorrect = q.getCorrectOption().name()
                .equalsIgnoreCase(ans.selected());

        correctnessList.add(isCorrect);
        if (isCorrect) correct++;
    }

    boolean passed = (correct * 100 / total) >= 70;

    var attempt = new UserQuizAttempt();
    attempt.setQuizId(quizId);
    attempt.setUserId(userId);
    attempt.setScore(correct);
    attempt.setCompletedAt(LocalDateTime.now());
    attemptRepo.save(attempt);

    return new SubmitResponse(correct, total, passed, correctnessList);
}

}
