package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.VoucherPageResponseDto;
import capstone_1.Ecotrack_backend.dto.response.VoucherViewDto;
import capstone_1.Ecotrack_backend.service.UserPointsService;
import capstone_1.Ecotrack_backend.service.VoucherService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/vouchers")
@CrossOrigin(origins = "*")   // để Flutter call được, sau này siết lại
public class VoucherController {

    private final VoucherService voucherService;
    private final UserPointsService userPointsService;   // ✅ thêm service điểm

    public VoucherController(VoucherService voucherService,
                             UserPointsService userPointsService) { // ✅ inject cả 2
        this.voucherService = voucherService;
        this.userPointsService = userPointsService;
    }

    // ========= API cũ: chỉ list voucher =========
    @GetMapping
    public List<VoucherViewDto> listVouchers() {
        return voucherService.getAvailableVouchers();
    }

    // ========= API đổi voucher =========
    @PostMapping("/{voucherId}/redeem")
    public void redeem(@PathVariable Long voucherId,
                       @RequestParam Long userId) {
        voucherService.redeemVoucher(userId, voucherId);
    }

    // ========= API mới: trả về cả điểm + list voucher =========
    // Ví dụ: GET /api/v1/vouchers/user/1/voucher-page
    @GetMapping("/user/{userId}/voucher-page")
    public ResponseEntity<VoucherPageResponseDto> getVoucherPage(@PathVariable Long userId) {

        // lấy điểm hiện tại của user
        int points = userPointsService.getUserPoints(userId);

        // lấy danh sách voucher (dùng hàm có sẵn)
        List<VoucherViewDto> vouchers = voucherService.getAvailableVouchers();

        VoucherPageResponseDto dto = new VoucherPageResponseDto(
                userId,
                points,
                vouchers
        );

        return ResponseEntity.ok(dto);
    }
}
