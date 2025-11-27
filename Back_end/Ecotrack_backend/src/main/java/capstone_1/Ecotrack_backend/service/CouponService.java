package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ApplyCouponRequest;
import capstone_1.Ecotrack_backend.dto.request.CreateCouponRequest;
import capstone_1.Ecotrack_backend.dto.request.UpdateCouponRequest;
import capstone_1.Ecotrack_backend.dto.response.ApplyCouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponStatisticsResponse;
import capstone_1.Ecotrack_backend.model.Coupon;
import capstone_1.Ecotrack_backend.repository.CouponRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CouponService {

    private final CouponRepository couponRepository;

    @Transactional
    public CouponResponse createCoupon(Long partnerId, CreateCouponRequest request) {
        // Kiểm tra mã coupon đã tồn tại chưa
        if (couponRepository.existsByCode(request.getCode())) {
            throw new RuntimeException("Mã coupon đã tồn tại");
        }

        // Kiểm tra ngày hết hạn phải sau ngày hiện tại
        if (request.getExpiryDate().isBefore(LocalDate.now())) {
            throw new RuntimeException("Ngày hết hạn phải sau ngày hiện tại");
        }

        // Chuyển đổi discountType từ string sang enum
        Coupon.DiscountType discountType;
        if ("percent".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.PERCENT;
        } else if ("fixed".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.FIXED;
        } else {
            throw new RuntimeException("Loại giảm giá không hợp lệ. Chỉ chấp nhận 'percent' hoặc 'fixed'");
        }

        // Tạo coupon mới
        Coupon coupon = new Coupon();
        coupon.setPartnerId(partnerId);
        coupon.setCode(request.getCode().toUpperCase());
        coupon.setDescription(request.getDescription());
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(request.getDiscountValue());
        coupon.setUsageLimit(request.getUsageLimit());
        coupon.setUsedCount(0);
        coupon.setExpiryDate(request.getExpiryDate());
        coupon.setIsActive(true);

        Coupon savedCoupon = couponRepository.save(coupon);
        return mapToResponse(savedCoupon);
    }

    @Transactional(readOnly = true)
    public List<CouponResponse> getAllCouponsByPartner(Long partnerId) {
        List<Coupon> coupons = couponRepository.findByPartnerIdOrderByCreatedAtDesc(partnerId);
        return coupons.stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional
    public CouponResponse updateCoupon(Long couponId, Long partnerId, UpdateCouponRequest request) {
        // Tìm coupon theo ID và kiểm tra thuộc về partner
        Optional<Coupon> couponOpt = couponRepository.findById(couponId);
        if (couponOpt.isEmpty()) {
            throw new RuntimeException("Không tìm thấy coupon với ID: " + couponId);
        }

        Coupon coupon = couponOpt.get();

        // Kiểm tra coupon thuộc về partner này
        if (!coupon.getPartnerId().equals(partnerId)) {
            throw new RuntimeException("Bạn không có quyền chỉnh sửa coupon này");
        }

        // Kiểm tra ngày hết hạn phải sau ngày hiện tại
        if (request.getExpiryDate().isBefore(LocalDate.now())) {
            throw new RuntimeException("Ngày hết hạn phải sau ngày hiện tại");
        }

        // Chuyển đổi discountType từ string sang enum
        Coupon.DiscountType discountType;
        if ("percent".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.PERCENT;
        } else if ("fixed".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.FIXED;
        } else {
            throw new RuntimeException("Loại giảm giá không hợp lệ. Chỉ chấp nhận 'percent' hoặc 'fixed'");
        }

        // Cập nhật thông tin coupon (không cho phép thay đổi code)
        coupon.setDescription(request.getDescription());
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(request.getDiscountValue());
        coupon.setUsageLimit(request.getUsageLimit());
        coupon.setExpiryDate(request.getExpiryDate());

        // Cập nhật isActive: nếu request có isActive thì dùng giá trị đó, nếu không thì check ngày hết hạn
        if (request.getIsActive() != null) {
            coupon.setIsActive(request.getIsActive());
        } else {
            // Nếu không có isActive trong request, tự động cập nhật dựa trên ngày hết hạn
            boolean isExpired = request.getExpiryDate().isBefore(LocalDate.now());
            coupon.setIsActive(!isExpired);
        }

        Coupon updatedCoupon = couponRepository.save(coupon);
        return mapToResponse(updatedCoupon);
    }

    @Transactional
    public void deleteCoupon(Long couponId, Long partnerId) {
        Optional<Coupon> couponOpt = couponRepository.findById(couponId);
        if (couponOpt.isEmpty()) {
            throw new RuntimeException("Không tìm thấy coupon với ID: " + couponId);
        }

        Coupon coupon = couponOpt.get();

        // Kiểm tra coupon thuộc về partner này
        if (!coupon.getPartnerId().equals(partnerId)) {
            throw new RuntimeException("Bạn không có quyền xóa coupon này");
        }

        // Xóa coupon
        couponRepository.delete(coupon);
    }

    @Transactional
    public ApplyCouponResponse applyCoupon(String code) {
        // Tìm coupon theo code
        Optional<Coupon> couponOpt = couponRepository.findByCode(code.toUpperCase());
        if (couponOpt.isEmpty()) {
            return ApplyCouponResponse.builder()
                    .success(false)
                    .message("Mã coupon không tồn tại")
                    .build();
        }

        Coupon coupon = couponOpt.get();
        LocalDate today = LocalDate.now();

        // Kiểm tra coupon có hoạt động không
        if (!coupon.getIsActive()) {
            return ApplyCouponResponse.builder()
                    .success(false)
                    .message("Coupon đã bị dừng hoạt động")
                    .build();
        }

        // Kiểm tra coupon có hết hạn không
        if (coupon.getExpiryDate().isBefore(today)) {
            return ApplyCouponResponse.builder()
                    .success(false)
                    .message("Coupon đã hết hạn")
                    .build();
        }

        // Kiểm tra đã đạt giới hạn sử dụng chưa
        if (coupon.getUsedCount() >= coupon.getUsageLimit()) {
            return ApplyCouponResponse.builder()
                    .success(false)
                    .message("Coupon đã hết lượt sử dụng")
                    .build();
        }

        // Tăng số lượt sử dụng
        coupon.setUsedCount(coupon.getUsedCount() + 1);
        couponRepository.save(coupon);

        // Trả về thông tin giảm giá
        return ApplyCouponResponse.builder()
                .success(true)
                .message("Áp dụng coupon thành công!")
                .discountType(coupon.getDiscountType().name())
                .discountValue(coupon.getDiscountValue())
                .description(coupon.getDescription())
                .build();
    }

    @Transactional(readOnly = true)
    public List<CouponResponse> getAvailableCoupons() {
        LocalDate today = LocalDate.now();
        List<Coupon> allCoupons = couponRepository.findAll();

        // Lọc các coupon đang active, chưa hết hạn, và chưa hết lượt sử dụng
        return allCoupons.stream()
                .filter(coupon -> coupon.getIsActive()
                        && !coupon.getExpiryDate().isBefore(today)
                        && coupon.getUsedCount() < coupon.getUsageLimit())
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt())) // Sắp xếp mới nhất trước
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public CouponStatisticsResponse getStatistics(Long partnerId) {
        List<Coupon> allCoupons = couponRepository.findByPartnerIdOrderByCreatedAtDesc(partnerId);
        LocalDate today = LocalDate.now();

        // 1. Đếm số coupon đang hoạt động (isActive = true và chưa hết hạn)
        int activeCoupons = (int) allCoupons.stream()
                .filter(coupon -> coupon.getIsActive() &&
                        (coupon.getExpiryDate().isAfter(today) || coupon.getExpiryDate().isEqual(today)))
                .count();

        // 2. Tổng lượt sử dụng
        int totalUsage = allCoupons.stream()
                .mapToInt(Coupon::getUsedCount)
                .sum();

        // 3. Tính tổng doanh thu từ các coupon đã sử dụng
        // Giả sử mỗi lần sử dụng coupon tạo ra giá trị tiết kiệm:
        // - PERCENT: Giả sử đơn hàng trung bình 100,000 VNĐ, tiết kiệm = discountValue% * 100,000
        // - FIXED: Tiết kiệm = discountValue
        long totalRevenue = 0;
        for (Coupon coupon : allCoupons) {
            if (coupon.getUsedCount() > 0) {
                if (coupon.getDiscountType() == Coupon.DiscountType.PERCENT) {
                    // Giả sử đơn hàng trung bình 100,000 VNĐ
                    double averageOrderValue = 100000.0;
                    double discountAmount = (coupon.getDiscountValue() / 100.0) * averageOrderValue;
                    totalRevenue += (long) (discountAmount * coupon.getUsedCount());
                } else {
                    // FIXED: discountValue là số tiền cố định
                    totalRevenue += (long) (coupon.getDiscountValue() * coupon.getUsedCount());
                }
            }
        }

        // 4. Tính ROI (Return on Investment)
        // ROI = (Doanh thu / Số coupon đã tạo) * 100
        // Hoặc đơn giản hóa: ROI = (Doanh thu / (Số coupon * 10000)) * 100
        // Giả sử chi phí tạo mỗi coupon là 10,000 VNĐ
        int totalCoupons = allCoupons.size();
        double roi = 0.0;
        if (totalCoupons > 0) {
            long estimatedCost = totalCoupons * 10000L; // Chi phí ước tính
            if (estimatedCost > 0) {
                roi = ((double) totalRevenue / estimatedCost) * 100.0;
            }
        }

        return CouponStatisticsResponse.builder()
                .totalRevenue(totalRevenue)
                .activeCoupons(activeCoupons)
                .totalUsage(totalUsage)
                .roi(roi)
                .build();
    }

    private CouponResponse mapToResponse(Coupon coupon) {
        // Kiểm tra coupon có hết hạn không
        boolean isExpired = coupon.getExpiryDate().isBefore(LocalDate.now());
        boolean isActive = coupon.getIsActive() && !isExpired;

        return CouponResponse.builder()
                .couponId(coupon.getCouponId())
                .code(coupon.getCode())
                .description(coupon.getDescription())
                .discountType(coupon.getDiscountType().name())
                .discountValue(coupon.getDiscountValue())
                .usageLimit(coupon.getUsageLimit())
                .usedCount(coupon.getUsedCount())
                .expiryDate(coupon.getExpiryDate())
                .isActive(isActive)
                .createdAt(coupon.getCreatedAt())
                .build();
    }
}

