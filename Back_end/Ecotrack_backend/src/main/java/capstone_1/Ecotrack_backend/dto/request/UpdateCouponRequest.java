package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateCouponRequest {
    private String title;

    private String shortDescription;

    private String description;

    private String category;

    private String badgeLabel;

    @NotBlank(message = "Loại giảm giá không được để trống")
    private String discountType; // "percent", "fixed" hoặc "free"

    private Double discountValue; // Optional, có thể là 0 nếu "free"

    private Double originalPrice;

    @NotNull(message = "Giới hạn sử dụng không được để trống")
    @Positive(message = "Giới hạn sử dụng phải lớn hơn 0")
    private Integer usageLimit;

    private Integer requiredPoints;

    private Integer maxRedeemPerUser; // Số lần tối đa 1 user có thể đổi voucher này (optional)

    private LocalDate startDate;

    @NotNull(message = "Ngày hết hạn không được để trống")
    private LocalDate expiryDate;

    private String locationScope;

    private String locationText;

    private Boolean isActive;
}

