package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ApiBadgeResponse<T> {
    private boolean success;
    private String message;
    private T data;
    private LocalDateTime timestamp;

    public static <T> ApiBadgeResponse<T> success(String message, T data) {
        return new ApiBadgeResponse<>(true, message, data, LocalDateTime.now());
    }

    public static <T> ApiBadgeResponse<T> error(String message) {
        return new ApiBadgeResponse<>(false, message, null, LocalDateTime.now());
    }
}
