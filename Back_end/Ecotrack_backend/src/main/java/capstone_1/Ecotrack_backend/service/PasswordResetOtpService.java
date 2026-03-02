package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;

public interface PasswordResetOtpService {

    ApiResponse<?> requestResetPassword(ResetPasswordRequestWithOtp request);

    ApiResponse<?> verifyOtpAndResetPassword(VerifyOtpRequest request);
}