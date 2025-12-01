package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CouponResponse {
    private Long couponId;
    private String code;
    private String description;
    private String discountType; // "PERCENT" hoặc "FIXED"
    private Double discountValue;
    private Integer usageLimit;
    private Integer usedCount;
    private LocalDate expiryDate;
    private Boolean isActive;
    private LocalDateTime createdAt;
}

