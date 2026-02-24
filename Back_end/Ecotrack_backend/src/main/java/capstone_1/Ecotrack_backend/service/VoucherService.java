package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.RedeemResult;
import capstone_1.Ecotrack_backend.dto.response.VoucherViewDto;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import org.springframework.security.core.context.SecurityContextHolder;
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
                    dto.setImageUrl(v.getThumbnailUrl());
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
    public RedeemResult redeemVoucher(Long voucherId) {

        String email = SecurityContextHolder.getContext()
                .getAuthentication()
                .getName();

        User user = userRepo.findByEmail(email).orElse(null);
        if (user == null) {
            return RedeemResult.fail("Không tìm thấy người dùng");
        }

        Voucher voucher = voucherRepo.findById(voucherId).orElse(null);
        if (voucher == null) {
            return RedeemResult.fail("Voucher không tồn tại");
        }

        if (voucher.getQuantity() == null || voucher.getQuantity() <= 0) {
            return RedeemResult.fail("Voucher đã hết lượt đổi");
        }

        if (voucher.getExpiryDate().isBefore(LocalDate.now())) {
            return RedeemResult.fail("Voucher đã hết hạn");
        }

        int pointsRequired = calculatePointsRequired(voucher);

        UserPoints userPoints = userPointsRepo.findById(user.getId()).orElse(null);
        if (userPoints == null) {
            return RedeemResult.fail("Không tìm thấy điểm người dùng");
        }

        if (userPoints.getPoints() < pointsRequired) {
            return RedeemResult.fail("Không đủ điểm để đổi voucher");
        }

        // ====== ĐỔI THÀNH CÔNG ======
        userPoints.setPoints(userPoints.getPoints() - pointsRequired);
        userPointsRepo.save(userPoints);

        voucher.setUsedCount(
                voucher.getUsedCount() == null ? 1 : voucher.getUsedCount() + 1
        );
        voucherRepo.save(voucher);

        UserVoucher uv = new UserVoucher();
        uv.setUserId(user.getId());
        uv.setVoucherId(voucherId);
        userVoucherRepo.save(uv);

        PointTransaction tx = new PointTransaction();
        tx.setUser(user);
        tx.setActionType(PointTransaction.ActionType.VOUCHER);
        tx.setPoints(-pointsRequired);
        tx.setDescription("Đổi voucher: " + voucher.getTitle());
        tx.setCreatedAt(LocalDateTime.now());
        pointTxRepo.save(tx);

        return RedeemResult.ok();
    }

}
