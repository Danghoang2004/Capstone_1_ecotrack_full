package capstone_1.Ecotrack_backend.service;

import java.time.LocalDateTime;

public record OtpData(String otp, LocalDateTime expiredAt) {
}