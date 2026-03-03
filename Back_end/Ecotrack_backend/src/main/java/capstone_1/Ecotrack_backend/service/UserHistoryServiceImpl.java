package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.UserHistoryResponse;
import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.UserQuizAttempt;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.UserQuizAttemptRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import capstone_1.Ecotrack_backend.repository.QuizRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class UserHistoryServiceImpl implements UserHistoryService {

    private final PointTransactionRepository pointRepo;
    private final WasteReportRepository reportRepo;
    private final UserQuizAttemptRepository quizRepo;
    private final QuizRepository quizMasterRepo; // Dùng để lấy title từ bảng quizzes

    @Override
    public Page<UserHistoryResponse> getPointHistory(Long userId, Pageable pageable) {
        // Khớp với PointTransactionRepository: dùng p.user.id
        // Spring Data JPA hỗ trợ findByUserId nếu field là user (id)
        return pointRepo.findByUserIdOrderByCreatedAtDesc(userId, pageable).map(this::mapPoint);
    }

    @Override
    public Page<UserHistoryResponse> getReportHistory(Long userId, Pageable pageable) {
        // Khớp với WasteReportRepository: findByUserId
        return reportRepo.findByUserIdOrderByCreatedAtDesc(userId, pageable).map(this::mapReport);
    }

    @Override
    public Page<UserHistoryResponse> getQuizHistory(Long userId, Pageable pageable) {
        // Khớp với UserQuizAttemptRepository: findByUserIdOrderByCompletedAtDesc
        return quizRepo
                .findByUserIdOrderByCompletedAtDesc(userId, pageable)
                .map(this::mapQuiz);
    }

    private UserHistoryResponse mapPoint(PointTransaction pt) {
        return UserHistoryResponse.builder()
                .id(pt.getTransactionId())
                .type("POINT")
                .title(pt.getActionType() != null ? pt.getActionType().name() : null)
                .description(pt.getDescription())
                .points(pt.getPoints())
                .createdAt(pt.getCreatedAt())
                .build();
    }

    private UserHistoryResponse mapReport(WasteReport wr) {
        return UserHistoryResponse.builder()
                .id(wr.getReportId())
                .type("REPORT")
                .title(wr.getTitle())
                .description(wr.getDescription())
                .status(wr.getStatus() != null ? wr.getStatus().name() : null)
                .createdAt(wr.getCreatedAt())
                .build();
    }

    private UserHistoryResponse mapQuiz(UserQuizAttempt qa) {
        // Vì UserQuizAttempt chỉ có quizId (Long), cần lấy title từ Quiz Entity
        String title = quizMasterRepo.findById(qa.getQuizId())
                .map(quiz -> quiz.getTitle())
                .orElse("Quiz " + qa.getQuizId());

        return UserHistoryResponse.builder()
                .id(qa.getId()) // Entity UserQuizAttempt dùng trường 'id'
                .type("QUIZ")
                .title(title)
                .score(qa.getScore())
                .points(qa.getScore()) // Map score sang points theo logic ban đầu
                .createdAt(qa.getCompletedAt())
                .build();
    }
}