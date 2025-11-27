package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class ApplyCouponResponse {
    private boolean success;
    private String message;
    private String discountType; // "PERCENT" hoặc "FIXED"
    private Double discountValue;
    private String description;
}

