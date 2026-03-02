package capstone_1.Ecotrack_backend.service;

import java.time.LocalDateTime;

public class OtpCache {

    private final String otp;
    private final String hashedPassword;
    private final LocalDateTime expiredAt;

    public OtpCache(String otp, String hashedPassword, LocalDateTime expiredAt) {
        this.otp = otp;
        this.hashedPassword = hashedPassword;
        this.expiredAt = expiredAt;
    }

    public String getOtp() {
        return otp;
    }

    public String getHashedPassword() {
        return hashedPassword;
    }

    public LocalDateTime getExpiredAt() {
        return expiredAt;
    }
}