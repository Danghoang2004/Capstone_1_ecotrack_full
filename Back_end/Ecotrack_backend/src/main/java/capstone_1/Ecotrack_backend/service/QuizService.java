package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.*;
import capstone_1.Ecotrack_backend.dto.request.*;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class QuizService {

        private final QuizRepository quizRepo;
        private final QuizQuestionRepository questionRepo;
        private final UserQuizAttemptRepository attemptRepo;
        private final PointTransactionRepository pointTransactionRepo;
        private final UserRepository userRepo;
        private final UserPointsRepository userPointsRepo;

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
                                                q.getCorrectOption() != null ? q.getCorrectOption().name() : null, // gửi
                                                                                                                   // correctKey
                                                List.of(
                                                                new QuizDetailDto.Option("A", q.getOptionA()),
                                                                new QuizDetailDto.Option("B", q.getOptionB()),
                                                                new QuizDetailDto.Option("C", q.getOptionC()),
                                                                new QuizDetailDto.Option("D", q.getOptionD()))))
                                .toList();

                return new QuizDetailDto(
                                quiz.getId(),
                                quiz.getTitle(),
                                quiz.getPointsReward(),
                                dtoQuestions);
        }

        public QuizSummaryDto getMyQuizSummary(Long userId) {

                // 1. Tổng điểm của user
                UserPoints up = userPointsRepo.findById(userId).orElse(null);
                int totalPoints = (up != null) ? up.getPoints() : 0;

                // 2. Lấy tất cả quiz (PUBLISHED hay tất cả tùy bạn)
                List<Quiz> quizzes = quizRepo.findAll();

                // 3. Lấy tất cả attempt của user
                List<UserQuizAttempt> attempts = attemptRepo.findByUserId(userId);

                // 4. Tạo map: quizId → điểm cao nhất
                Map<Long, Integer> bestScoreByQuiz = attempts.stream()
                                .collect(Collectors.toMap(
                                                UserQuizAttempt::getQuizId, // lấy quizId trong bảng attempt
                                                UserQuizAttempt::getScore, // điểm
                                                Integer::max // nếu trùng quizId → lấy điểm cao nhất
                                ));

                // 5. Build danh sách overview item
                List<QuizOverviewItemDto> items = quizzes.stream()
                                .map(q -> {
                                        Long qid = q.getId();
                                        Integer bestScore = bestScoreByQuiz.get(qid);

                                        boolean completed = bestScore != null;

                                        long totalQuestions = 20; // chỉ tính dựa trên 20 câu FE sử dụng

                                        int percent = 0;
                                        if (completed) {
                                                percent = (int) Math.round(bestScore * 100.0 / totalQuestions);
                                        }

                                        int reward = q.getPointsReward() != null ? q.getPointsReward() : 0;

                                        // thời gian tính theo số câu (ví dụ 30s mỗi câu)
                                        int timeSec = 30;

                                        return new QuizOverviewItemDto(
                                                        qid,
                                                        q.getTitle(),
                                                        "Bộ câu hỏi môi trường tổng hợp", // 👈 thêm description
                                                        completed,
                                                        percent,
                                                        (int) totalQuestions, // số câu = 20
                                                        timeSec, // thời gian tổng
                                                        reward // điểm thưởng
                                        );

                                })
                                .toList();

                // 6. Đếm số quiz đã hoàn thành
                long completedCount = items.stream()
                                .filter(QuizOverviewItemDto::isCompleted)
                                .count();

                return new QuizSummaryDto(
                                (int) completedCount,
                                quizzes.size(),
                                totalPoints,
                                items);
        }


        public SubmitResponse submit(Long quizId, Long userId, SubmitRequest req) {

                // Lấy quiz + user từ DB
                var quiz = quizRepo.findById(quizId).orElseThrow();
                User user = userRepo.findById(userId).orElseThrow();

                int total = req.answers().size();
                int correct = 0;
                List<Boolean> correctnessList = new ArrayList<>();

                for (var ans : req.answers()) {
                        var q = questionRepo.findById(ans.questionId()).orElse(null);

                        if (q == null) {
                                correctnessList.add(false);
                                continue;
                        }

                        boolean isCorrect = q.getCorrectOption().name()
                                        .equalsIgnoreCase(ans.selected());

                        correctnessList.add(isCorrect);
                        if (isCorrect)
                                correct++;
                }

                boolean passed = (correct * 100 / total) >= 70;

                // Lưu lịch sử làm quiz
                var attempt = new UserQuizAttempt();
                attempt.setQuizId(quizId);
                attempt.setUserId(userId);
                attempt.setScore(correct);
                attempt.setCompletedAt(LocalDateTime.now());
                attemptRepo.save(attempt);

                // ⭐ CỘNG ĐIỂM KHI LÀM QUIZ (VD: chỉ khi pass)
                if (passed) {
                        int reward = quiz.getPointsReward() != null ? quiz.getPointsReward() : 0;

                        capstone_1.Ecotrack_backend.model.PointTransaction pt = new capstone_1.Ecotrack_backend.model.PointTransaction();
                        pt.setUser(user);
                        pt.setActionType(PointTransaction.ActionType.QUIZ);
                        pt.setPoints(reward);
                        pt.setDescription("Hoàn thành quiz: " + quiz.getTitle());
                        pt.setCreatedAt(LocalDateTime.now());

                        pointTransactionRepo.save(pt);
                        UserPoints up = userPointsRepo.findById(userId).orElseGet(() -> {
                                // Nếu chưa có bản ghi UserPoints cho user này, tạo mới
                                UserPoints newUp = new UserPoints();
                                newUp.setUserId(userId);
                                newUp.setUser(user);
                                newUp.setPoints(0);
                                return newUp;
                        });

                        // Cộng dồn điểm mới vào điểm hiện tại
                        up.setPoints(up.getPoints() + reward);
                        userPointsRepo.save(up);
                }

                return new SubmitResponse(correct, total, passed, correctnessList);
        }

}