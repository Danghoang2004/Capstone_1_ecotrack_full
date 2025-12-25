package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.Quiz;
import capstone_1.Ecotrack_backend.model.QuizQuestion;
import capstone_1.Ecotrack_backend.repository.QuizQuestionRepository;
import capstone_1.Ecotrack_backend.repository.QuizRepository;
import capstone_1.Ecotrack_backend.repository.UserQuizAttemptRepository;
import jakarta.transaction.Transactional;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.List;

@Service
public class QuizImportService {
    @Autowired
    private QuizQuestionRepository questionRepository;

    @Autowired
    private QuizRepository quizRepository;
    @Autowired
    private UserQuizAttemptRepository userQuizAttemptRepository;

    public void importQuestionsFromExcel(MultipartFile file, Long quizId) throws Exception {
        Quiz quiz = quizRepository.findById(quizId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy bộ đề thi"));

        Workbook workbook = new XSSFWorkbook(file.getInputStream());
        Sheet sheet = workbook.getSheetAt(0); // Lấy sheet đầu tiên

        List<QuizQuestion> questions = new ArrayList<>();

        for (int i = 1; i <= sheet.getLastRowNum(); i++) {
            Row row = sheet.getRow(i);
            if (row == null || row.getCell(0) == null) continue;

            QuizQuestion q = new QuizQuestion();
            q.setQuiz(quiz);
            q.setQuestionText(row.getCell(0).getStringCellValue());
            q.setOptionA(row.getCell(1).getStringCellValue());
            q.setOptionB(row.getCell(2).getStringCellValue());
            q.setOptionC(row.getCell(3).getStringCellValue());
            q.setOptionD(row.getCell(4).getStringCellValue());

            // Xử lý chuyển đổi String -> Enum Key
            try {
                String cellValue = row.getCell(5).getStringCellValue().toUpperCase().trim();
                q.setCorrectOption(QuizQuestion.Key.valueOf(cellValue));
            } catch (IllegalArgumentException | NullPointerException e) {
                // Nếu giá trị trong Excel không phải A, B, C, D hoặc ô bị trống
                throw new RuntimeException("Lỗi tại dòng " + (i + 1) + ": Đáp án đúng phải là A, B, C hoặc D");
            }

            questions.add(q);
        }
        questionRepository.saveAll(questions);
        workbook.close();
    }

    @Transactional
    public Quiz createQuizWithQuestions(String title, Integer pointsReward, MultipartFile file) throws Exception {
        Quiz newQuiz = new Quiz();
        newQuiz.setTitle(title);
        newQuiz.setPointsReward(pointsReward);
        newQuiz.setStatus(Quiz.Status.DRAFT);
        newQuiz = quizRepository.save(newQuiz);
        importQuestionsFromExcel(file, newQuiz.getId());

        return newQuiz;
    }

    @Transactional
    public void deleteQuizAndRelatedData(Long quizId) {
        if (!quizRepository.existsById(quizId)) {
            throw new RuntimeException("Không tìm thấy bộ đề thi để xóa");
        }

        // 1. Xóa lịch sử làm bài (Bảng con)
        userQuizAttemptRepository.deleteByQuizId(quizId);

        // 2. Xóa các câu hỏi (Bảng con)
        questionRepository.deleteByQuiz_Id(quizId);

        // 3. Cuối cùng, xóa chính bộ đề đó (Bảng cha) bằng hàm mặc định
        quizRepository.deleteById(quizId);
    }
}
