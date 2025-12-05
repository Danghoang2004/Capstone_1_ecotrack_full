package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "coupons") // <-- BẢNG THẬT TRONG DB
public class Voucher {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "coupon_id")
    private Long voucherId; // FE dùng voucherId

    @Column(name = "partner_id", nullable = false)
    private Long partnerId;

    // dùng code làm title hiển thị
    @Column(name = "code", nullable = false)
    private String title;

    @Column(name = "description")
    private String description;

    @Column(name = "discount_value", nullable = false)
    private Double value; // số, lát DTO convert sang String

    @Column(name = "usage_limit", nullable = false)
    private Integer usageLimit; // tổng số lượt dùng

    @Column(name = "used_count", nullable = false)
    private Integer usedCount; // đã dùng bao nhiêu

    @Column(name = "expiry_date", nullable = false)
    private LocalDate expiryDate;

    @Column(name = "is_active", nullable = false)
    private Boolean active;

    @Column(name = "badge_label")
    private String badgeLabel;

    @Column(name = "category")
    private String category; // FOOD / SHOPPING / TRANSPORT / SERVICE

    // ===== convenience getter =====

    // Số lượng còn lại
    @Transient
    public Integer getQuantity() {
        if (usageLimit == null)
            return 0;
        int used = (usedCount == null ? 0 : usedCount);
        return usageLimit - used;
    }

    // Điểm cần để đổi – demo: lấy bằng discount_value
    @Transient
    public Integer getPointsRequired() {
        if (value == null)
            return 0;
        return value.intValue();
    }

    // ===== getters / setters =====

    public Long getVoucherId() {
        return voucherId;
    }

    public void setVoucherId(Long voucherId) {
        this.voucherId = voucherId;
    }

    public Long getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(Long partnerId) {
        this.partnerId = partnerId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Double getValue() {
        return value;
    }

    public void setValue(Double value) {
        this.value = value;
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

    public Boolean getActive() {
        return active;
    }

    public void setActive(Boolean active) {
        this.active = active;
    }

    public String getBadgeLabel() {
        return badgeLabel;
    }

    public void setBadgeLabel(String badgeLabel) {
        this.badgeLabel = badgeLabel;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }
}
