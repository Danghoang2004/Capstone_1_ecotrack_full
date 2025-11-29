package capstone_1.Ecotrack_backend.controller.partner;

import capstone_1.Ecotrack_backend.dto.request.CreateCouponRequest;
import capstone_1.Ecotrack_backend.dto.request.UpdateCouponRequest;
import capstone_1.Ecotrack_backend.dto.response.CouponResponse;
import capstone_1.Ecotrack_backend.dto.response.CouponStatisticsResponse;
import capstone_1.Ecotrack_backend.model.Partner;
import capstone_1.Ecotrack_backend.repository.PartnerRepository;
import capstone_1.Ecotrack_backend.service.CouponService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/partner/coupons")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class CouponController {

    private final CouponService couponService;
    private final PartnerRepository partnerRepository;

    @GetMapping
    public ResponseEntity<List<CouponResponse>> getAllCoupons(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy partner_id từ user_id
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner với user_id: " + userId));
        Long partnerId = partner.getPartnerId();

        List<CouponResponse> coupons = couponService.getAllCouponsByPartner(partnerId);
        return ResponseEntity.ok(coupons);
    }

    @PostMapping
    public ResponseEntity<CouponResponse> createCoupon(
            @Valid @RequestBody CreateCouponRequest request,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy partner_id từ user_id
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner với user_id: " + userId));
        Long partnerId = partner.getPartnerId();

        try {
            CouponResponse coupon = couponService.createCoupon(partnerId, request);
            return ResponseEntity.status(HttpStatus.CREATED).body(coupon);
        } catch (RuntimeException e) {
            Map<String, String> errorResponse = new HashMap<>();
            errorResponse.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(null);
        }
    }

    @PutMapping("/{couponId}")
    public ResponseEntity<CouponResponse> updateCoupon(
            @PathVariable Long couponId,
            @Valid @RequestBody UpdateCouponRequest request,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy partner_id từ user_id
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner với user_id: " + userId));
        Long partnerId = partner.getPartnerId();

        try {
            CouponResponse coupon = couponService.updateCoupon(couponId, partnerId, request);
            return ResponseEntity.ok(coupon);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @GetMapping("/statistics")
    public ResponseEntity<CouponStatisticsResponse> getStatistics(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy partner_id từ user_id
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner với user_id: " + userId));
        Long partnerId = partner.getPartnerId();

        CouponStatisticsResponse statistics = couponService.getStatistics(partnerId);
        return ResponseEntity.ok(statistics);
    }

    @DeleteMapping("/{couponId}")
    public ResponseEntity<Void> deleteCoupon(
            @PathVariable Long couponId,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        // Lấy partner_id từ user_id
        Partner partner = partnerRepository.findByUserId(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy partner với user_id: " + userId));
        Long partnerId = partner.getPartnerId();

        try {
            couponService.deleteCoupon(couponId, partnerId);
            return ResponseEntity.noContent().build();
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
    }

    @PostMapping("/upload-image")
    public ResponseEntity<Map<String, String>> uploadImage(
            @RequestParam("image") MultipartFile image,
            HttpServletRequest httpRequest) {
        Long userId = (Long) httpRequest.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        try {
            if (image == null || image.isEmpty()) {
                return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
            }

            // Tạo thư mục upload nếu chưa có
            String uploadDir = "D:/Code/Capstone_1_ecotrack_full/Back_end/Ecotrack_backend/uploads/coupons/";
            Files.createDirectories(Paths.get(uploadDir));

            // Tạo tên file unique
            String fileName = System.currentTimeMillis() + "_" + image.getOriginalFilename();
            Path filePath = Paths.get(uploadDir + fileName);

            // Lưu file
            Files.copy(image.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

            // Trả về URL
            String imageUrl = "/uploads/coupons/" + fileName;
            Map<String, String> response = new HashMap<>();
            response.put("imageUrl", imageUrl);
            response.put("message", "Upload ảnh thành công");

            return ResponseEntity.ok(response);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
}

