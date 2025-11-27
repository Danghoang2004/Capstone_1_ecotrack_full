package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.VoucherViewDto;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.UserVoucherRepository;
import capstone_1.Ecotrack_backend.repository.VoucherRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
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
    private final UserRepository userRepo;   // <-- thêm

    public VoucherService(VoucherRepository voucherRepo,
                          PartnerRepository partnerRepo,
                          UserPointsRepository userPointsRepo,
                          UserVoucherRepository userVoucherRepo,
                          PointTransactionRepository pointTxRepo,
                          UserRepository userRepo) {  // <-- thêm vào constructor
        this.voucherRepo = voucherRepo;
        this.partnerRepo = partnerRepo;
        this.userPointsRepo = userPointsRepo;
        this.userVoucherRepo = userVoucherRepo;
        this.pointTxRepo = pointTxRepo;
        this.userRepo = userRepo;
    }

    public List<VoucherViewDto> getAvailableVouchers() {
        return voucherRepo.findAvailable(LocalDate.now()).stream()
                .map(v -> {
                    Partner p = partnerRepo.findById(v.getPartnerId()).orElse(null);
                    VoucherViewDto dto = new VoucherViewDto();
                    dto.setVoucherId(v.getVoucherId());
                    dto.setTitle(v.getTitle());
                    dto.setDescription(v.getDescription());
                    dto.setValue(v.getValue());
                    dto.setImageUrl(v.getImageUrl());
                    dto.setQuantity(v.getQuantity());
                    dto.setPointsRequired(v.getPointsRequired());
                    dto.setExpiryDate(v.getExpiryDate());
                    if (p != null) {
                        dto.setPartnerName(p.getCompanyName());
                        dto.setPartnerLogoUrl(p.getLogoUrl());
                    }
                    return dto;
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public void redeemVoucher(Long userId, Long voucherId) {
        Voucher voucher = voucherRepo.findById(voucherId)
                .orElseThrow(() -> new RuntimeException("Voucher not found"));

        if (voucher.getQuantity() == null || voucher.getQuantity() <= 0) {
            throw new RuntimeException("Voucher out of stock");
        }
        if (voucher.getExpiryDate().isBefore(LocalDate.now())) {
            throw new RuntimeException("Voucher expired");
        }

        // lấy user points
        UserPoints userPoints = userPointsRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User points not found"));

        if (userPoints.getPoints() < voucher.getPointsRequired()) {
            throw new RuntimeException("Not enough points");
        }

        // lấy User entity để log transaction
        User user = userRepo.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // trừ điểm
        userPoints.setPoints(userPoints.getPoints() - voucher.getPointsRequired());
        userPointsRepo.save(userPoints);

        // trừ số lượng voucher
        voucher.setQuantity(voucher.getQuantity() - 1);
        voucherRepo.save(voucher);

        // lưu user_vouchers
        UserVoucher uv = new UserVoucher();
        uv.setUserId(userId);
        uv.setVoucherId(voucherId);
        userVoucherRepo.save(uv);

        // log điểm
        PointTransaction tx = new PointTransaction();
    tx.setUser(user);
    tx.setActionType(PointTransaction.ActionType.VOUCHER);
    tx.setPoints(-voucher.getPointsRequired());

    String title = voucher.getTitle();
    if (title == null || title.isBlank()) {
        // fallback nếu không có title
        tx.setDescription("Đổi voucher #" + voucherId);
    } else {
        tx.setDescription("" + title);
    }

    tx.setCreatedAt(LocalDateTime.now());
    pointTxRepo.save(tx);
}
}