package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDate;

@Data
public class CreateCouponRequest {
    @NotBlank(message = "Mã coupon không được để trống")
    private String code;

    private String title;

    private String shortDescription;

    private String description;

    private String category; // Ăn uống / Mua sắm / Di chuyển / Dịch vụ / Khác

    private String badgeLabel;

    @NotBlank(message = "Loại giảm giá không được để trống")
    private String discountType; // "percent", "fixed" hoặc "free"

    private Double discountValue; // Optional, có thể là 0 nếu "free"

    private Double originalPrice; // Giá gốc (optional)

    @NotNull(message = "Giới hạn sử dụng không được để trống")
    @Positive(message = "Giới hạn sử dụng phải lớn hơn 0")
    private Integer usageLimit;

    private Integer requiredPoints; // Optional, có thể là 0 nếu "free"

    private Integer maxRedeemPerUser; // Số lần tối đa 1 user có thể đổi voucher này (optional)

    private LocalDate startDate; // Ngày bắt đầu

    @NotNull(message = "Ngày hết hạn không được để trống")
    private LocalDate expiryDate;

    private String locationScope; // NATIONWIDE / PROVINCE

    private String locationText; // Tên địa điểm hiển thị

    private String thumbnailUrl; // Optional
}

