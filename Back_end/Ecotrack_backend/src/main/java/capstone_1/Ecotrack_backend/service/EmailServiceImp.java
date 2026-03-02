package capstone_1.Ecotrack_backend.service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class EmailServiceImp implements EmailService {

    private final JavaMailSender mailSender;

    @Override
    public void sendMessage(String from, String to, String subject, String text) {
        try {
            MimeMessage message = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");

            helper.setFrom(from);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(text, true); // gửi HTML

            mailSender.send(message);

        } catch (MessagingException e) {
            throw new RuntimeException("Lỗi gửi email", e);
        }
    }

    @Override
    public void sendOtpEmail(String to, String otp) {

        String htmlContent = """
                <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 40px 20px; background-color: #f0f4f0; color: #333;">
                    <div style="max-width: 520px; margin: auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.08); border-top: 6px solid #2E7D32;">

                        <div style="padding: 30px 20px; text-align: center; background-color: #fdfdfd;">
                            <h1 style="color: #2E7D32; margin: 0; font-size: 28px; letter-spacing: 1px;">EcoTrack</h1>
                            <p style="margin: 5px 0 0; color: #666; font-size: 14px; text-transform: uppercase; letter-spacing: 2px;">Hệ thống quản lý môi trường</p>
                        </div>

                        <div style="padding: 20px 40px 40px;">
                            <h2 style="color: #2E7D32; font-size: 20px; margin-bottom: 20px; text-align: center;">Xác thực đặt lại mật khẩu</h2>

                            <p style="line-height: 1.6;">Xin chào,</p>
                            <p style="line-height: 1.6;">Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu cho tài khoản <strong>EcoTrack</strong> của bạn. Vui lòng sử dụng mã xác thực dưới đây để tiếp tục:</p>

                            <div style="margin: 35px 0; text-align: center;">
                                <div style="display: inline-block; padding: 15px 30px; background-color: #e8f5e9; border: 2px dashed #2E7D32; border-radius: 12px;">
                                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 36px; font-weight: bold; letter-spacing: 8px; color: #2E7D32;">
                                        %s
                                    </span>
                                </div>
                                <p style="font-size: 13px; color: #666; margin-top: 15px;">
                                    <i>Mã OTP này có hiệu lực trong <b>5 phút</b></i>
                                </p>
                            </div>

                            <div style="background-color: #fff9c4; padding: 15px; border-left: 4px solid #fbc02d; border-radius: 4px; margin-bottom: 25px;">
                                <p style="margin: 0; font-size: 13px; color: #5d4037;">
                                    <b>Lưu ý:</b> Nếu bạn không yêu cầu thay đổi này, hãy đổi mật khẩu ngay lập tức hoặc liên hệ bộ phận hỗ trợ để bảo vệ tài khoản.
                                </p>
                            </div>

                            <p style="font-size: 14px; line-height: 1.6;">Trân trọng,<br><strong>Đội ngũ EcoTrack</strong></p>
                        </div>

                        <div style="background-color: #2E7D32; padding: 20px; text-align: center; color: #ffffff; font-size: 12px;">
                            <p style="margin: 0 0 10px;">© 2026 EcoTrack Project. All rights reserved.</p>
                            <div style="opacity: 0.8;">
                                Bạn nhận được email này vì đã đăng ký tài khoản tại EcoTrack.
                            </div>
                        </div>
                    </div>
                </div>
                """
                .formatted(otp);

        sendMessage(
                "EcoTrack <no-reply@ecotrack.com>",
                to,
                "EcoTrack – Mã OTP đặt lại mật khẩu",
                htmlContent);
    }
}