package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.request.ApplyCouponRequest;
import capstone_1.Ecotrack_backend.dto.response.ApplyCouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponResponse;
import capstone_1.Ecotrack_backend.service.CouponService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/user/coupons")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class UserCouponController {

    private final CouponService couponService;

    @GetMapping("/available")
    public ResponseEntity<List<CouponResponse>> getAvailableCoupons() {
        try {
            List<CouponResponse> coupons = couponService.getAvailableCoupons();
            return ResponseEntity.ok(coupons);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }

    @PostMapping("/apply")
    public ResponseEntity<ApplyCouponResponse> applyCoupon(
            @Valid @RequestBody ApplyCouponRequest request) {
        try {
            ApplyCouponResponse response = couponService.applyCoupon(request.getCode());
            if (response.isSuccess()) {
                return ResponseEntity.ok(response);
            } else {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(response);
            }
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(ApplyCouponResponse.builder()
                            .success(false)
                            .message("Lỗi server: " + e.getMessage())
                            .build());
        }
    }
}

