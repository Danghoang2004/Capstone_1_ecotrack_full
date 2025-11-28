package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;

public record SubmitResponse(
        int correct,
        int total,
        boolean passed,
        List<Boolean> correctnessList
) {}
