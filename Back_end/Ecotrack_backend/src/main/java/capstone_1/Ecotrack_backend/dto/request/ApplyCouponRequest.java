package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class ApplyCouponRequest {
    @NotBlank(message = "Mã coupon không được để trống")
    private String code;
}

