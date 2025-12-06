package capstone_1.Ecotrack_backend.dto.request;

import java.util.List;

public record SubmitRequest(
        List<Answer> answers
) {
    public record Answer(Long questionId, String selected) {}
}


