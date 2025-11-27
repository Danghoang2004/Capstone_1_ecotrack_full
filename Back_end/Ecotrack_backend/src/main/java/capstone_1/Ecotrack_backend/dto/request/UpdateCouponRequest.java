package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.time.LocalDate;

@Data
public class UpdateCouponRequest {
    private String description;

    @NotBlank(message = "Loại giảm giá không được để trống")
    private String discountType; // "percent" hoặc "fixed"

    @NotNull(message = "Giá trị giảm không được để trống")
    @Positive(message = "Giá trị giảm phải lớn hơn 0")
    private Double discountValue;

    @NotNull(message = "Giới hạn sử dụng không được để trống")
    @Positive(message = "Giới hạn sử dụng phải lớn hơn 0")
    private Integer usageLimit;

    @NotNull(message = "Ngày hết hạn không được để trống")
    private LocalDate expiryDate;

    private Boolean isActive;
}

