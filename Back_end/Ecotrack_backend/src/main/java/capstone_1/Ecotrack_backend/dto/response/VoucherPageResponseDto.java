package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;

public class VoucherPageResponseDto {

    private Long userId;
    private int points;

    private List<VoucherViewDto> vouchers;

    public VoucherPageResponseDto(Long userId, int points, List<VoucherViewDto> vouchers) {
        this.userId = userId;
        this.points = points;
        this.vouchers = vouchers;
    }

    public Long getUserId() { return userId; }
    public int getPoints() { return points; }
    public List<VoucherViewDto> getVouchers() { return vouchers; }

    public void setUserId(Long userId) { this.userId = userId; }
    public void setPoints(int points) { this.points = points; }
    public void setVouchers(List<VoucherViewDto> vouchers) { this.vouchers = vouchers; }
}
