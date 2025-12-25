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
    private String title;
    private String shortDescription;
    private String description;
    private String thumbnailUrl;
    private String category;
    private String badgeLabel;
    private String discountType; // "PERCENT" hoặc "FIXED"
    private Double discountValue;
    private Double originalPrice;
    private Double finalPrice;
    private Integer usageLimit;
    private Integer usedCount;
    private Integer requiredPoints;
    private LocalDate startDate;
    private LocalDate expiryDate;
    private String locationScope;
    private String locationText;
    private Boolean isActive;
    private LocalDateTime createdAt;

    // Partner information
    private String partnerName;
    private String partnerLogoUrl;
    private String serviceArea;
}

