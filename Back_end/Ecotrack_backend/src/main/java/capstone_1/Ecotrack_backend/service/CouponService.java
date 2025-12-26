package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ApplyCouponRequest;
import capstone_1.Ecotrack_backend.dto.request.CreateCouponRequest;
import capstone_1.Ecotrack_backend.dto.request.UpdateCouponRequest;
import capstone_1.Ecotrack_backend.dto.response.ApplyCouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponStatisticsResponse;
import capstone_1.Ecotrack_backend.model.Coupon;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.CouponRepository;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class CouponService {

    private final CouponRepository couponRepository;
    private final PartnerRepository partnerRepository;
    private final UserPointsRepository userPointsRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final UserRepository userRepository;

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
        } else if ("free".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.PERCENT; // Dùng PERCENT nhưng discountValue = 0
        } else {
            throw new RuntimeException("Loại giảm giá không hợp lệ. Chỉ chấp nhận 'percent', 'fixed' hoặc 'free'");
        }

        // Xử lý "free" - set discountValue = 0 nếu chưa có
        Double discountValue = request.getDiscountValue();
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            discountValue = 0.0;
        }

        // Xử lý requiredPoints - set = 0 nếu "free"
        Integer requiredPoints = request.getRequiredPoints();
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            requiredPoints = 0;
        }

        // Tính finalPrice
        Double finalPrice = calculateFinalPrice(request.getOriginalPrice(), discountType, discountValue);
        // Nếu "free" thì finalPrice = 0
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            finalPrice = 0.0;
        }
        Partner partner = partnerRepository.findById(partnerId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner"));

        // Tạo coupon mới
        Coupon coupon = new Coupon();
        coupon.setPartner(partner);
        coupon.setCode(request.getCode().toUpperCase());
        coupon.setTitle(request.getTitle());
        coupon.setShortDescription(request.getShortDescription());
        coupon.setDescription(request.getDescription());
        coupon.setCategory(request.getCategory());
        coupon.setBadgeLabel(request.getBadgeLabel());
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(discountValue);
        coupon.setOriginalPrice(request.getOriginalPrice());
        coupon.setFinalPrice(finalPrice);
        coupon.setUsageLimit(request.getUsageLimit());
        coupon.setRequiredPoints(requiredPoints);
        coupon.setMaxRedeemPerUser(request.getMaxRedeemPerUser());
        coupon.setUsedCount(0);
        coupon.setStartDate(request.getStartDate());
        coupon.setExpiryDate(request.getExpiryDate());
        coupon.setLocationScope(request.getLocationScope());
        coupon.setLocationText(request.getLocationText());
        coupon.setIsActive(true);
        if (request.getThumbnailUrl() != null && !request.getThumbnailUrl().isEmpty()) {
            coupon.setThumbnailUrl(request.getThumbnailUrl());
        }

        Coupon savedCoupon = couponRepository.save(coupon);
        return mapToResponse(savedCoupon);
    }

    // Phương thức tính finalPrice
    private Double calculateFinalPrice(Double originalPrice, Coupon.DiscountType discountType, Double discountValue) {
        if (originalPrice == null || originalPrice <= 0) {
            return null;
        }

        if (discountType == Coupon.DiscountType.PERCENT) {
            // Giảm theo phần trăm: finalPrice = originalPrice * (1 - discountValue/100)
            return originalPrice * (1 - discountValue / 100.0);
        } else {
            // Giảm số tiền cố định: finalPrice = originalPrice - discountValue
            double result = originalPrice - discountValue;
            return result > 0 ? result : 0.0;
        }
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
        } else if ("free".equalsIgnoreCase(request.getDiscountType())) {
            discountType = Coupon.DiscountType.PERCENT; // Dùng PERCENT nhưng discountValue = 0
        } else {
            throw new RuntimeException("Loại giảm giá không hợp lệ. Chỉ chấp nhận 'percent', 'fixed' hoặc 'free'");
        }

        // Xử lý "free" - set discountValue = 0 nếu chưa có
        Double discountValue = request.getDiscountValue();
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            discountValue = 0.0;
        }

        // Xử lý requiredPoints - set = 0 nếu "free"
        Integer requiredPoints = request.getRequiredPoints();
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            requiredPoints = 0;
        }

        // Tính lại finalPrice
        Double finalPrice = calculateFinalPrice(request.getOriginalPrice(), discountType, discountValue);
        // Nếu "free" thì finalPrice = 0
        if ("free".equalsIgnoreCase(request.getDiscountType())) {
            finalPrice = 0.0;
        }

        // Cập nhật thông tin coupon (không cho phép thay đổi code)
        coupon.setTitle(request.getTitle());
        coupon.setShortDescription(request.getShortDescription());
        coupon.setDescription(request.getDescription());
        coupon.setCategory(request.getCategory());
        coupon.setBadgeLabel(request.getBadgeLabel());
        coupon.setDiscountType(discountType);
        coupon.setDiscountValue(discountValue);
        coupon.setOriginalPrice(request.getOriginalPrice());
        coupon.setFinalPrice(finalPrice);
        coupon.setUsageLimit(request.getUsageLimit());
        coupon.setRequiredPoints(requiredPoints);
        coupon.setMaxRedeemPerUser(request.getMaxRedeemPerUser());
        coupon.setStartDate(request.getStartDate());
        coupon.setExpiryDate(request.getExpiryDate());
        coupon.setLocationScope(request.getLocationScope());
        coupon.setLocationText(request.getLocationText());

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

        // Tự động dừng hoạt động nếu đã đủ số lượng sử dụng
        if (coupon.getUsedCount() >= coupon.getUsageLimit()) {
            coupon.setIsActive(false);
        }

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
        // Kiểm tra start_date nếu có
        return allCoupons.stream()
                .filter(coupon -> {
                    boolean isActive = coupon.getIsActive();
                    boolean notExpired = !coupon.getExpiryDate().isBefore(today);
                    boolean notStarted = coupon.getStartDate() == null ||
                                        !coupon.getStartDate().isAfter(today);
                    boolean hasQuantity = coupon.getUsedCount() < coupon.getUsageLimit();
                    return isActive && notExpired && notStarted && hasQuantity;
                })
                .sorted((a, b) -> b.getCreatedAt().compareTo(a.getCreatedAt())) // Sắp xếp mới nhất trước
                .map(coupon -> {
                    CouponResponse response = mapToResponse(coupon);
                    // Join với partner để lấy thông tin
                    Optional<Partner> partnerOpt = partnerRepository.findById(coupon.getPartnerId());
                    if (partnerOpt.isPresent()) {
                        Partner partner = partnerOpt.get();
                        response.setPartnerName(partner.getCompanyName());
                        response.setPartnerLogoUrl(partner.getLogoUrl());
                        response.setServiceArea(coupon.getLocationText()); // Dùng location_text làm service_area
                    }
                    return response;
                })
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

        // 3. Tính tổng giá trị voucher đã được đổi (dựa trên finalPrice)
        // Voucher được đổi bằng điểm, nên tính giá trị thực tế của voucher đã đổi
        long totalRevenue = 0;
        for (Coupon coupon : allCoupons) {
            if (coupon.getUsedCount() > 0 && coupon.getFinalPrice() != null) {
                // Tính dựa trên giá trị thực tế của voucher (finalPrice * số lần đã đổi)
                totalRevenue += (long) (coupon.getFinalPrice() * coupon.getUsedCount());
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

    @Transactional
    public Map<String, Object> redeemCoupon(Long userId, Long couponId) {
        Map<String, Object> response = new HashMap<>();

        // 1. Kiểm tra coupon có tồn tại không
        Coupon coupon = couponRepository.findById(couponId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy voucher"));

        // 2. Kiểm tra coupon có active không
        if (!coupon.getIsActive()) {
            throw new RuntimeException("Voucher đã bị dừng hoạt động");
        }

        // 3. Kiểm tra coupon có hết hạn không
        LocalDate today = LocalDate.now();
        if (coupon.getExpiryDate().isBefore(today)) {
            throw new RuntimeException("Voucher đã hết hạn");
        }

        // 4. Kiểm tra coupon đã bắt đầu chưa
        if (coupon.getStartDate() != null && coupon.getStartDate().isAfter(today)) {
            throw new RuntimeException("Voucher chưa đến thời gian sử dụng");
        }

        // 5. Kiểm tra còn lượt sử dụng không
        if (coupon.getUsedCount() >= coupon.getUsageLimit()) {
            throw new RuntimeException("Voucher đã hết lượt sử dụng");
        }

        // 5.1. Kiểm tra giới hạn số lần redeem cho 1 user
        if (coupon.getMaxRedeemPerUser() != null && coupon.getMaxRedeemPerUser() > 0) {
            // Tìm pattern trong description: "[couponId:xxx]"
            String couponIdPattern = "[couponId:" + coupon.getCouponId() + "]";

            // Đếm số lần user đã redeem coupon này
            // Query sẽ tìm pattern trong description với CONCAT để tránh SQL injection
            long userRedemptionCount = pointTransactionRepository
                .countVoucherRedemptionsByUserAndCoupon(userId, couponIdPattern);

            // Kiểm tra nếu đã đạt giới hạn (so sánh >= để chặn ngay khi đạt giới hạn)
            if (userRedemptionCount >= coupon.getMaxRedeemPerUser()) {
                throw new RuntimeException(
                    String.format("Bạn đã đạt giới hạn số lần đổi voucher này! Mỗi người chỉ được đổi %d lần. Bạn đã đổi %d lần.",
                        coupon.getMaxRedeemPerUser(), userRedemptionCount)
                );
            }
        }

        // 6. Kiểm tra user có đủ điểm không (chỉ kiểm tra nếu requiredPoints > 0)
        int requiredPoints = coupon.getRequiredPoints() != null ? coupon.getRequiredPoints() : 0;

        if (requiredPoints > 0) {
            UserPoints userPoints = userPointsRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy thông tin điểm"));

            if (userPoints.getPoints() < requiredPoints) {
                throw new RuntimeException(
                    String.format("Không đủ điểm! Cần %d điểm, hiện có %d điểm",
                        requiredPoints, userPoints.getPoints())
                );
            }

            // 7. Trừ điểm user
            userPoints.setPoints(userPoints.getPoints() - requiredPoints);
            userPointsRepository.save(userPoints);
        }

        // 8. Tăng used_count của coupon
        coupon.setUsedCount(coupon.getUsedCount() + 1);

        // 8.1. Tự động dừng hoạt động nếu đã đủ số lượng sử dụng
        if (coupon.getUsedCount() >= coupon.getUsageLimit()) {
            coupon.setIsActive(false);
        }

        couponRepository.save(coupon);

        // 9. Tạo point transaction để track số lần redeem (luôn tạo, dù miễn phí hay không)
        // Với voucher miễn phí: points = 0, với voucher có phí: points = -requiredPoints
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user"));

        PointTransaction transaction = new PointTransaction();
        transaction.setUser(user);
        transaction.setActionType(PointTransaction.ActionType.VOUCHER);
        transaction.setPoints(requiredPoints > 0 ? -requiredPoints : 0); // Số âm nếu có phí, 0 nếu miễn phí
        // Lưu coupon_id vào description để có thể query sau này
        transaction.setDescription("Đổi voucher: " + coupon.getTitle() + " [couponId:" + coupon.getCouponId() + "]");
        transaction.setCreatedAt(LocalDateTime.now());
        pointTransactionRepository.save(transaction);

        // 10. Trả về kết quả
        response.put("success", true);
        response.put("message", "Đổi voucher thành công!");
        response.put("couponId", coupon.getCouponId());
        response.put("title", coupon.getTitle());
        response.put("code", coupon.getCode());
        response.put("pointsSpent", requiredPoints);
        if (requiredPoints > 0) {
            UserPoints userPoints = userPointsRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("Không tìm thấy thông tin điểm"));
            response.put("remainingPoints", userPoints.getPoints());
        } else {
            response.put("remainingPoints", 0);
        }

        return response;
    }

    private CouponResponse mapToResponse(Coupon coupon) {
        // Kiểm tra coupon có hết hạn không
        boolean isExpired = coupon.getExpiryDate().isBefore(LocalDate.now());
        boolean isActive = coupon.getIsActive() && !isExpired;

        return CouponResponse.builder()
                .couponId(coupon.getCouponId())
                .code(coupon.getCode())
                .title(coupon.getTitle())
                .shortDescription(coupon.getShortDescription())
                .description(coupon.getDescription())
                .thumbnailUrl(coupon.getThumbnailUrl())
                .category(coupon.getCategory())
                .badgeLabel(coupon.getBadgeLabel())
                .discountType(coupon.getDiscountType().name())
                .discountValue(coupon.getDiscountValue())
                .originalPrice(coupon.getOriginalPrice())
                .finalPrice(coupon.getFinalPrice())
                .usageLimit(coupon.getUsageLimit())
                .usedCount(coupon.getUsedCount())
                .requiredPoints(coupon.getRequiredPoints())
                .startDate(coupon.getStartDate())
                .expiryDate(coupon.getExpiryDate())
                .locationScope(coupon.getLocationScope())
                .locationText(coupon.getLocationText())
                .isActive(isActive)
                .createdAt(coupon.getCreatedAt())
                .build();
    }
}

