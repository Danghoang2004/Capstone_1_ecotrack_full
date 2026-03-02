package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;

@Service
@RequiredArgsConstructor
public class PasswordResetOtpServiceImpl implements PasswordResetOtpService {

    private final UserRepository userRepository;
    private final EmailService emailService;
    private final PasswordEncoder passwordEncoder;

    private static final int OTP_EXPIRE_MINUTES = 5;

    // 🔥 LƯU OTP TẠM TRONG RAM
    private static final Map<String, OtpCache> OTP_STORE = new ConcurrentHashMap<>();

    @Override
    public void requestResetPassword(ResetPasswordRequestWithOtp request) {

        if (!request.getNewPassword().equals(request.getConfirmPassword())) {
            throw new RuntimeException("Mật khẩu xác nhận không khớp");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

        String hashedPassword = passwordEncoder.encode(request.getNewPassword());

        // Tạo OTP 6 số
        String otp = String.valueOf(ThreadLocalRandom.current().nextInt(100000, 1000000));

        OTP_STORE.put(
                user.getEmail(),
                new OtpCache(
                        otp,
                        hashedPassword,
                        LocalDateTime.now().plusMinutes(OTP_EXPIRE_MINUTES)));

        emailService.sendMessage(
                "no-reply@ecotrack.com",
                user.getEmail(),
                "EcoTrack - Mã OTP đặt lại mật khẩu",
                buildEmailContent(otp));
    }

    @Override
    public void verifyOtpAndResetPassword(VerifyOtpRequest request) {
        OtpCache cache = OTP_STORE.get(request.getEmail());

        if (cache == null ||
                LocalDateTime.now().isAfter(cache.getExpiredAt()) ||
                !cache.getOtp().equals(request.getOtp())) {

            throw new RuntimeException("OTP không hợp lệ hoặc đã hết hạn");
        }

        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Email không tồn tại"));

        user.setPassword(cache.getHashedPassword());
        userRepository.save(user);

        OTP_STORE.remove(request.getEmail());
    }

    private String buildEmailContent(String otp) {
        return "<div style=\"font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; max-width: 600px; margin: 0 auto; border: 1px solid #eeeeee; border-radius: 10px; overflow: hidden;\">"
                +
                "    <div style=\"background-color: #27ae60; padding: 20px; text-align: center;\">" +
                "        <h1 style=\"color: white; margin: 0; font-size: 28px; letter-spacing: 1px;\">EcoTrack</h1>" +
                "    </div>" +
                "    <div style=\"padding: 30px; color: #2c3e50;\">" +
                "        <h2 style=\"color: #27ae60; margin-top: 0;\">Xác thực đặt lại mật khẩu</h2>" +
                "        <p style=\"font-size: 16px;\">Chào bạn,</p>" +
                "        <p style=\"font-size: 15px; line-height: 1.6;\">Chúng tôi nhận được yêu cầu thay đổi mật khẩu cho tài khoản EcoTrack của bạn. Vui lòng sử dụng mã xác thực (OTP) dưới đây để tiếp tục:</p>"
                +
                "        " +
                "        <div style=\"background-color: #f8f9fa; border-radius: 8px; border: 2px dashed #27ae60; padding: 20px; text-align: center; margin: 30px 0;\">"
                +
                "            <span style=\"font-size: 36px; font-weight: bold; color: #27ae60; letter-spacing: 8px;\">"
                + otp + "</span>" +
                "        </div>" +
                "        " +
                "        <p style=\"font-size: 14px; color: #7f8c8d;\"><i>Lưu ý: Mã này có hiệu lực trong <b>"
                + OTP_EXPIRE_MINUTES
                + " phút</b>. Vì lý do bảo mật, tuyệt đối không chia sẻ mã này với bất kỳ ai.</i></p>" +
                "        <hr style=\"border: 0; border-top: 1px solid #eee; margin: 25px 0;\">" +
                "        <p style=\"font-size: 13px; color: #95a5a6;\">Nếu bạn không yêu cầu thay đổi mật khẩu, bạn có thể an tâm bỏ qua email này.</p>"
                +
                "    </div>" +
                "    <div style=\"background-color: #f4f4f4; padding: 20px; text-align: center; color: #bdc3c7; font-size: 12px;\">"
                +
                "        <p style=\"margin: 5px 0;\">© 2026 EcoTrack Team - Hướng tới tương lai bền vững</p>" +
                "        <p style=\"margin: 5px 0;\">Email này được gửi tự động, vui lòng không phản hồi.</p>" +
                "    </div>" +
                "</div>";
    }
}