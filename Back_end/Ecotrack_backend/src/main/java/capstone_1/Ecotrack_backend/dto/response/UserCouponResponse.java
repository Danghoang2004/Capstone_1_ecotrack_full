package capstone_1.Ecotrack_backend.dto.response;

import capstone_1.Ecotrack_backend.model.UserCouponStatus;
import lombok.Getter;
import lombok.Setter;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Getter
@Setter
public class UserCouponResponse {

    private Long userCouponId;
    private Long couponId;
    private String title;
    private String description;
    private String partnerName;
    private String thumbnailUrl;
    private UserCouponStatus status;
    private LocalDate expiryDate;
    private LocalDateTime usedAt;

    // ⚠️ Constructor dùng cho JPQL (BẮT BUỘC)
    public UserCouponResponse(
            Long userCouponId,
            Long couponId,
            String title,
            String description,
            String partnerName,
            String thumbnailUrl,
            UserCouponStatus status,
            LocalDate expiryDate,
            LocalDateTime usedAt
    ) {
        this.userCouponId = userCouponId;
        this.couponId = couponId;
        this.title = title;
        this.description = description;
        this.partnerName = partnerName;
        this.thumbnailUrl = thumbnailUrl;
        this.status = status;
        this.expiryDate = expiryDate;
        this.usedAt = usedAt;
    }
}
