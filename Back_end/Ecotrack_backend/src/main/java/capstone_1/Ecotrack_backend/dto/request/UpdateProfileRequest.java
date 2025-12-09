package capstone_1.Ecotrack_backend.dto.request;

import lombok.Data;

@Data
public class UpdateProfileRequest {
    // Thông tin chung
    private String fullName;
    private String location;
    private String phoneNumber;
    private String gender; // M, F, O
    private String avatarUrl;

    // Đổi mật khẩu (Nếu user không nhập thì để null)
    private String currentPassword;
    private String newPassword;
    private String confirmPassword;
}