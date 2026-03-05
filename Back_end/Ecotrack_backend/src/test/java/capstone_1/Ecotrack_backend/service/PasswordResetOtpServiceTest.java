package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.time.LocalDateTime;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class PasswordResetOtpServiceTest {

    @Mock
    private UserRepository userRepository;

    @Mock
    private EmailService emailService;

    @Mock
    private PasswordEncoder passwordEncoder;

    @InjectMocks
    private PasswordResetOtpServiceImpl passwordResetOtpService;

    private final String email = "user@example.com";

    @BeforeEach
    void cleanOtpStore() {
        // Đảm bảo không có OTP rác còn lại cho email này
        OtpStore.remove(email);
    }

    @Test
    void requestResetPassword_ShouldReturnError_WhenEmailIsBlank() {
        ResetPasswordRequestWithOtp request = new ResetPasswordRequestWithOtp();
        request.setEmail("  ");

        ApiResponse<?> response = passwordResetOtpService.requestResetPassword(request);

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getCode()).isEqualTo("EMAIL_REQUIRED");
        assertThat(response.getMessage()).isEqualTo("Email không được để trống");

        verifyNoInteractions(userRepository, emailService);
    }

    @Test
    void requestResetPassword_ShouldGenerateOtp_SaveAndSendEmail() {
        ResetPasswordRequestWithOtp request = new ResetPasswordRequestWithOtp();
        request.setEmail(email);

        User user = new User();
        user.setEmail(email);

        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));

        ArgumentCaptor<String> otpCaptor = ArgumentCaptor.forClass(String.class);

        ApiResponse<?> response = passwordResetOtpService.requestResetPassword(request);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getCode()).isEqualTo("OTP_SENT");
        assertThat(response.getMessage()).isEqualTo("OTP đã được gửi tới email");

        Object data = response.getData();
        assertThat(data).isInstanceOf(Map.class);

        Map<?, ?> dataMap = (Map<?, ?>) data;
        assertThat(dataMap.get("email")).isEqualTo(email);
        assertThat(dataMap.get("expireMinutes")).isEqualTo(5);

        verify(emailService).sendOtpEmail(eq(email), otpCaptor.capture());
        String sentOtp = otpCaptor.getValue();
        assertThat(sentOtp).hasSize(6);

        OtpData stored = OtpStore.get(email);
        assertThat(stored).isNotNull();
        assertThat(stored.otp()).isEqualTo(sentOtp);
        assertThat(stored.expiredAt()).isAfter(LocalDateTime.now());
    }

    @Test
    void verifyOtpAndResetPassword_ShouldReturnError_WhenOtpNotFound() {
        VerifyOtpRequest request = new VerifyOtpRequest();
        request.setEmail(email);
        request.setOtp("123456");
        request.setNewPassword("new-password");

        OtpStore.remove(email);

        ApiResponse<?> response = passwordResetOtpService.verifyOtpAndResetPassword(request);

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getCode()).isEqualTo("OTP_NOT_FOUND");
        assertThat(response.getMessage()).isEqualTo("OTP không tồn tại");
    }

    @Test
    void verifyOtpAndResetPassword_ShouldReturnError_WhenOtpExpired() {
        OtpStore.save(email, new OtpData("123456", LocalDateTime.now().minusMinutes(1)));

        VerifyOtpRequest request = new VerifyOtpRequest();
        request.setEmail(email);
        request.setOtp("123456");
        request.setNewPassword("new-password");

        ApiResponse<?> response = passwordResetOtpService.verifyOtpAndResetPassword(request);

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getCode()).isEqualTo("OTP_EXPIRED");
        assertThat(response.getMessage()).isEqualTo("OTP đã hết hạn");

        assertThat(OtpStore.get(email)).isNull();
    }

    @Test
    void verifyOtpAndResetPassword_ShouldReturnError_WhenOtpInvalid() {
        OtpStore.save(email, new OtpData("111111", LocalDateTime.now().plusMinutes(5)));

        VerifyOtpRequest request = new VerifyOtpRequest();
        request.setEmail(email);
        request.setOtp("222222");
        request.setNewPassword("new-password");

        ApiResponse<?> response = passwordResetOtpService.verifyOtpAndResetPassword(request);

        assertThat(response.isSuccess()).isFalse();
        assertThat(response.getCode()).isEqualTo("OTP_INVALID");
        assertThat(response.getMessage()).isEqualTo("OTP không chính xác");

        assertThat(OtpStore.get(email)).isNotNull();
    }

    @Test
    void verifyOtpAndResetPassword_ShouldUpdatePassword_WhenOtpValidAndNotExpired() {
        String otp = "654321";
        OtpStore.save(email, new OtpData(otp, LocalDateTime.now().plusMinutes(5)));

        User user = new User();
        user.setEmail(email);
        user.setPassword("old-password");

        when(userRepository.findByEmail(email)).thenReturn(Optional.of(user));
        when(passwordEncoder.encode("new-password")).thenReturn("encoded-password");

        VerifyOtpRequest request = new VerifyOtpRequest();
        request.setEmail(email);
        request.setOtp(otp);
        request.setNewPassword("new-password");

        ApiResponse<?> response = passwordResetOtpService.verifyOtpAndResetPassword(request);

        assertThat(response.isSuccess()).isTrue();
        assertThat(response.getCode()).isEqualTo("RESET_PASSWORD_SUCCESS");
        assertThat(response.getMessage()).isEqualTo("Đặt lại mật khẩu thành công");

        verify(passwordEncoder).encode("new-password");
        verify(userRepository).save(user);
        assertThat(user.getPassword()).isEqualTo("encoded-password");

        assertThat(OtpStore.get(email)).isNull();
    }
}

