package capstone_1.Ecotrack_backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class UpdateUserRequest {
    private String fullName; // Tên đầy đủ (từ UserProfile)
    private String email; // Email (từ User)
    private String username; // Username (từ User)
    private String password; // Password mới (từ User, optional - chỉ update nếu có)
    private Boolean isActive; // Trạng thái hoạt động (từ User.enabled)
}

