package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;

public interface PasswordResetOtpService {

    void requestResetPassword(ResetPasswordRequestWithOtp request);

    void verifyOtpAndResetPassword(VerifyOtpRequest request);
}