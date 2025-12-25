package capstone_1.Ecotrack_backend.dto.response;



import java.util.List;

public record QuizDetailDto(
        Long id,
        String title,
        Integer pointsReward,
        List<Question> questions
) {
    public record Question(Long id, String text,String correctKey,  List<Option> options) {}
    public record Option(String key, String text) {}
}

