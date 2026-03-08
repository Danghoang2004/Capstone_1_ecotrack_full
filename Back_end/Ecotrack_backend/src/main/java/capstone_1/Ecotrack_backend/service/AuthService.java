package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AuthResponse; // DTO trả về cho Flutter

public interface AuthService {
    // Khai báo hàm đăng nhập Facebook
    AuthResponse loginWithFacebook(String fbToken);
    
    // Về sau bạn có thể dời hàm registerUser từ UserService sang đây cho chuẩn kiến trúc
}