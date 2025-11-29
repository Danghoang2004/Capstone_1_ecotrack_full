package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "coupons")
public class Coupon {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coupon_id")
    private Long couponId;

    @Column(name = "partner_id", nullable = false)
    private Long partnerId;

    @Column(name = "code", nullable = false, unique = true, length = 50)
    private String code;

    @Column(name = "title", length = 255)
    private String title;

    @Column(name = "short_description", length = 500)
    private String shortDescription;

    @Column(name = "description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "thumbnail_url", length = 255)
    private String thumbnailUrl;

    @Column(name = "category", length = 50)
    private String category; // Ăn uống / Mua sắm / Di chuyển / Dịch vụ / Khác

    @Column(name = "badge_label", length = 50)
    private String badgeLabel;

    @Enumerated(EnumType.STRING)
    @Column(name = "discount_type", nullable = false)
    private DiscountType discountType;

    @Column(name = "discount_value", nullable = false)
    private Double discountValue;

    @Column(name = "original_price")
    private Double originalPrice;

    @Column(name = "final_price")
    private Double finalPrice;

    @Column(name = "usage_limit", nullable = false)
    private Integer usageLimit;

    @Column(name = "used_count", nullable = false)
    private Integer usedCount = 0;

    @Column(name = "required_points")
    private Integer requiredPoints;

    @Column(name = "max_redeem_per_user")
    private Integer maxRedeemPerUser; // Số lần tối đa 1 user có thể đổi voucher này

    @Column(name = "start_date")
    private LocalDate startDate;

    @Column(name = "expiry_date", nullable = false)
    private LocalDate expiryDate;

    @Column(name = "location_scope", length = 50)
    private String locationScope; // NATIONWIDE / PROVINCE

    @Column(name = "location_text", length = 255)
    private String locationText;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    public enum DiscountType {
        PERCENT,    // Phần trăm
        FIXED       // Số tiền cố định
    }

    public Coupon() {
    }

    public Coupon(Long couponId, Long partnerId, String code, String description, DiscountType discountType, Double discountValue, Integer usageLimit, Integer usedCount, LocalDate expiryDate, Boolean isActive, LocalDateTime createdAt) {
        this.couponId = couponId;
        this.partnerId = partnerId;
        this.code = code;
        this.description = description;
        this.discountType = discountType;
        this.discountValue = discountValue;
        this.usageLimit = usageLimit;
        this.usedCount = usedCount;
        this.expiryDate = expiryDate;
        this.isActive = isActive;
        this.createdAt = createdAt;
    }

    // Getters and Setters
    public Long getCouponId() {
        return couponId;
    }

    public void setCouponId(Long couponId) {
        this.couponId = couponId;
    }

    public Long getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(Long partnerId) {
        this.partnerId = partnerId;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public DiscountType getDiscountType() {
        return discountType;
    }

    public void setDiscountType(DiscountType discountType) {
        this.discountType = discountType;
    }

    public Double getDiscountValue() {
        return discountValue;
    }

    public void setDiscountValue(Double discountValue) {
        this.discountValue = discountValue;
    }

    public Integer getUsageLimit() {
        return usageLimit;
    }

    public void setUsageLimit(Integer usageLimit) {
        this.usageLimit = usageLimit;
    }

    public Integer getUsedCount() {
        return usedCount;
    }

    public void setUsedCount(Integer usedCount) {
        this.usedCount = usedCount;
    }

    public LocalDate getExpiryDate() {
        return expiryDate;
    }

    public void setExpiryDate(LocalDate expiryDate) {
        this.expiryDate = expiryDate;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean isActive) {
        this.isActive = isActive;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getThumbnailUrl() {
        return thumbnailUrl;
    }

    public void setThumbnailUrl(String thumbnailUrl) {
        this.thumbnailUrl = thumbnailUrl;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getBadgeLabel() {
        return badgeLabel;
    }

    public void setBadgeLabel(String badgeLabel) {
        this.badgeLabel = badgeLabel;
    }

    public Double getOriginalPrice() {
        return originalPrice;
    }

    public void setOriginalPrice(Double originalPrice) {
        this.originalPrice = originalPrice;
    }

    public Double getFinalPrice() {
        return finalPrice;
    }

    public void setFinalPrice(Double finalPrice) {
        this.finalPrice = finalPrice;
    }

    public LocalDate getStartDate() {
        return startDate;
    }

    public void setStartDate(LocalDate startDate) {
        this.startDate = startDate;
    }

    public String getLocationScope() {
        return locationScope;
    }

    public void setLocationScope(String locationScope) {
        this.locationScope = locationScope;
    }

    public String getLocationText() {
        return locationText;
    }

    public void setLocationText(String locationText) {
        this.locationText = locationText;
    }

    public Integer getRequiredPoints() {
        return requiredPoints;
    }

    public void setRequiredPoints(Integer requiredPoints) {
        this.requiredPoints = requiredPoints;
    }

    public Integer getMaxRedeemPerUser() {
        return maxRedeemPerUser;
    }

    public void setMaxRedeemPerUser(Integer maxRedeemPerUser) {
        this.maxRedeemPerUser = maxRedeemPerUser;
    }
}

