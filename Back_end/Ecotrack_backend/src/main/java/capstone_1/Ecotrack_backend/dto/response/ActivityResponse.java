package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class ActivityResponse {
    private Long transactionId;
    private String actionType;
    private Integer points;
    private String description;
    private String createdAt; // ISO string
}