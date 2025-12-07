package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.VoucherViewDto;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class VoucherService {

    private final VoucherRepository voucherRepo;
    private final PartnerRepository partnerRepo;
    private final UserPointsRepository userPointsRepo;
    private final UserVoucherRepository userVoucherRepo;
    private final PointTransactionRepository pointTxRepo;
    private final UserRepository userRepo;

    public VoucherService(VoucherRepository voucherRepo,
            PartnerRepository partnerRepo,
            UserPointsRepository userPointsRepo,
            UserVoucherRepository userVoucherRepo,
            PointTransactionRepository pointTxRepo,
            UserRepository userRepo) {
        this.voucherRepo = voucherRepo;
        this.partnerRepo = partnerRepo;
        this.userPointsRepo = userPointsRepo;
        this.userVoucherRepo = userVoucherRepo;
        this.pointTxRepo = pointTxRepo;
        this.userRepo = userRepo;
    }

    // ================== LẤY DANH SÁCH VOUCHER/COUPON ==================
    public List<VoucherViewDto> getAvailableVouchers() {
        return voucherRepo.findAvailable(LocalDate.now()).stream()
                .map(v -> {
                    Partner p = partnerRepo.findById(v.getPartnerId()).orElse(null);

                    VoucherViewDto dto = new VoucherViewDto();
                    dto.setVoucherId(v.getVoucherId());
                    dto.setTitle(v.getTitle());
                    dto.setDescription(v.getDescription());

                    // value trong DB là DOUBLE → convert sang String cho FE
                    dto.setValue(v.getValue() != null ? v.getValue().toString() : null);

                    // quantity được tính từ usageLimit - usedCount (getter @Transient trong entity)
                    dto.setQuantity(v.getQuantity());

                    // điểm cần đổi: ưu tiên getter getPointsRequired() nếu có, fallback
                    // discount_value
                    dto.setPointsRequired(calculatePointsRequired(v));

                    dto.setExpiryDate(v.getExpiryDate());

                    // gửi category lên FE: FOOD / SHOPPING / TRANSPORT / SERVICE
                    String cat = v.getCategory();
                    dto.setCategory(cat != null ? cat.toUpperCase() : "SHOPPING");

                    if (p != null) {
                        dto.setPartnerName(p.getCompanyName());
                        dto.setPartnerLogoUrl(p.getLogoUrl());
                    }

                    return dto;
                })
                .collect(Collectors.toList());
    }

    private int calculatePointsRequired(Voucher v) {
        // nếu entity có getter getPointsRequired() riêng thì dùng trước
        if (v.getPointsRequired() != null) {
            return v.getPointsRequired();
        }
        if (v.getValue() == null) {
            return 0;
        }
        return v.getValue().intValue();
    }

    // ================== REDEEM VOUCHER ==================
    @Transactional
    public void redeemVoucher(Long userId, Long voucherId) {
        // 1. Lấy voucher
        Voucher voucher = voucherRepo.findById(voucherId)
                .orElseThrow(() -> new RuntimeException("Voucher not found"));

        // 2. Kiểm tra còn lượt dùng (quantity > 0)
        Integer quantity = voucher.getQuantity();
        if (quantity == null || quantity <= 0) {
            throw new RuntimeException("Voucher out of stock");
        }

        // 3. Kiểm tra hạn
        if (voucher.getExpiryDate().isBefore(LocalDate.now())) {
            throw new RuntimeException("Voucher expired");
        }

        // 4. Tính điểm cần để đổi
        int pointsRequired = calculatePointsRequired(voucher);

        // 5. Lấy user points
        UserPoints userPoints = userPointsRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User points not found"));

        if (userPoints.getPoints() < pointsRequired) {
            throw new RuntimeException("Not enough points");
        }

        // 6. Lấy User entity để log transaction
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 7. Trừ điểm
        userPoints.setPoints(userPoints.getPoints() - pointsRequired);
        userPointsRepo.save(userPoints);

        // 8. Tăng used_count để quantity giảm (usageLimit - usedCount)
        int usedCount = voucher.getUsedCount() == null ? 0 : voucher.getUsedCount();
        voucher.setUsedCount(usedCount + 1);
        voucherRepo.save(voucher);

        // 9. Lưu user_vouchers (entity UserVoucher đang map tới bảng
        // user_coupons/user_vouchers)
        UserVoucher uv = new UserVoucher();
        uv.setUserId(userId);
        uv.setVoucherId(voucherId);
        userVoucherRepo.save(uv);

        // 10. Log giao dịch điểm
        PointTransaction tx = new PointTransaction();
        tx.setUser(user); // dùng entity User
        tx.setActionType(PointTransaction.ActionType.VOUCHER);
        tx.setPoints(-pointsRequired);

        String title = voucher.getTitle();
        if (title == null || title.isBlank()) {
            tx.setDescription("Đổi voucher #" + voucherId);
        } else {
            tx.setDescription(title);
        }

        tx.setCreatedAt(LocalDateTime.now());
        pointTxRepo.save(tx);
    }
}
