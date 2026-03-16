package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Random;

@Service
@RequiredArgsConstructor
public class PasswordResetOtpServiceImpl implements PasswordResetOtpService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    private static final int OTP_EXPIRE_MINUTES = 5;

    @Override
    public ApiResponse<?> requestResetPassword(ResetPasswordRequestWithOtp request) {

        // 1. Check email
        if (request.getEmail() == null || request.getEmail().isBlank()) {
            return ApiResponse.error(
                    "EMAIL_REQUIRED",
                    "Email không được để trống");
        }

        // 2. Tìm user theo email
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

        // 3. Tạo OTP
        String otp = String.valueOf(100000 + new Random().nextInt(900000));
        LocalDateTime expiredAt = LocalDateTime.now().plusMinutes(OTP_EXPIRE_MINUTES);

        // 4. Lưu OTP tạm
        OtpStore.save(user.getEmail(), new OtpData(otp, expiredAt));

        // 5. Gửi email OTP
        emailService.sendOtpEmail(user.getEmail(), otp);

        // 6. Response cho FE
        return ApiResponse.success(
                "OTP_SENT",
                "OTP đã được gửi tới email",
                Map.of(
                        "email", user.getEmail(),
                        "expireMinutes", OTP_EXPIRE_MINUTES));
    }

    @Override
    public ApiResponse<?> verifyOtpAndResetPassword(VerifyOtpRequest request) {

        OtpData otpData = OtpStore.get(request.getEmail());

        if (otpData == null) {
            return ApiResponse.error("OTP_NOT_FOUND", "OTP không tồn tại");
        }

        if (LocalDateTime.now().isAfter(otpData.expiredAt())) {
            OtpStore.remove(request.getEmail());
            return ApiResponse.error("OTP_EXPIRED", "OTP đã hết hạn");
        }

        if (!otpData.otp().equals(request.getOtp())) {
            return ApiResponse.error("OTP_INVALID", "OTP không chính xác");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("User không tồn tại"));

        user.setPassword(passwordEncoder.encode(request.getNewPassword()));
        userRepository.save(user);

        OtpStore.remove(request.getEmail());

        return ApiResponse.success(
                "RESET_PASSWORD_SUCCESS",
                "Đặt lại mật khẩu thành công",
                null);
    }
}