package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class CouponStatisticsResponse {
    private Long totalRevenue; // Tổng giá trị voucher đã đổi (VNĐ)
    private Integer activeCoupons; // Số coupon đang hoạt động
    private Integer totalUsage; // Tổng lượt sử dụng coupon
    private Double roi; // Return on Investment (%)
}

