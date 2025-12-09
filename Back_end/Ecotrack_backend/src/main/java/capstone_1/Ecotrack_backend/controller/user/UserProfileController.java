package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserProfile;
import capstone_1.Ecotrack_backend.repository.UserProfileRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;

@RestController
@RequestMapping("/api/user/profile")
@CrossOrigin
public class UserProfileController {

    @Autowired
    private UserProfileRepository userProfileRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    // Dùng POST để dễ xử lý multipart/form-data
    @PostMapping(value = "/update", consumes = "multipart/form-data")
    public UserProfile updateProfile(
            HttpServletRequest request,
            @RequestParam(value = "fullName", required = false) String fullName,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "phoneNumber", required = false) String phoneNumber,
            @RequestParam(value = "currentPassword", required = false) String currentPassword,
            @RequestParam(value = "newPassword", required = false) String newPassword,
            @RequestParam(value = "confirmPassword", required = false) String confirmPassword,
            @RequestParam(value = "avatar", required = false) MultipartFile avatar
    ) {
        try {
            // 1. Lấy UserID từ Request (được set từ Filter xác thực)
            // Lưu ý: Nếu bạn dùng Spring Security chuẩn thì có thể lấy từ SecurityContextHolder
            // Nhưng tôi viết theo style code mẫu của bạn:
            Long userId = (Long) request.getAttribute("userId");
            // Fallback: Nếu request attribute null, thử lấy từ token header (tuỳ logic authen của bạn)
            if (userId == null) {
                // Ví dụ lấy theo username nếu userId không có sẵn trong attribute
                // String username = SecurityContextHolder.getContext().getAuthentication().getName();
                // ... tìm user ...
                throw new RuntimeException("Unauthorized: Missing UserID");
            }

            // 2. Tìm User và Profile trong DB
            User user = userRepository.findById(userId)
                    .orElseThrow(() -> new RuntimeException("User not found"));

            UserProfile profile = userProfileRepository.findByUser(user)
                    .orElseThrow(() -> new RuntimeException("Profile not found"));

            // 3. Xử lý lưu file ảnh (Giống hệt mẫu bạn gửi)
            if (avatar != null && !avatar.isEmpty()) {
                // Đường dẫn thư mục lưu avatar (tôi đổi folder reports -> avatars cho gọn)
                String uploadDir = "D:/project_Capstone_1_full/Back_end/Ecotrack_backend/uploads/avatars/";

                // Tạo thư mục nếu chưa có
                Files.createDirectories(Paths.get(uploadDir));

                // Tạo tên file duy nhất
                String fileName = System.currentTimeMillis() + "_" + avatar.getOriginalFilename();
                Path filePath = Paths.get(uploadDir + fileName);

                // Lưu file
                Files.copy(avatar.getInputStream(), filePath, StandardCopyOption.REPLACE_EXISTING);

                // Lưu đường dẫn web vào biến (để set vào profile sau)
                String avatarUrl = "/uploads/avatars/" + fileName;
                profile.setAvatarUrl(avatarUrl);
            }

            // 4. Cập nhật các thông tin khác (Chỉ update nếu có gửi lên)
            if (fullName != null && !fullName.isEmpty()) profile.setFullName(fullName);
            if (location != null && !location.isEmpty()) profile.setLocation(location);
            if (phoneNumber != null && !phoneNumber.isEmpty()) profile.setPhone_number(phoneNumber);

            // 5. Xử lý đổi mật khẩu (Logic cũ tích hợp vào đây)
            if (currentPassword != null && !currentPassword.isEmpty()) {
                if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
                    throw new RuntimeException("Mật khẩu hiện tại không đúng");
                }
                if (newPassword != null && !newPassword.equals(confirmPassword)) {
                    throw new RuntimeException("Mật khẩu xác nhận không khớp");
                }
                if (newPassword != null && !newPassword.isEmpty()) {
                    user.setPassword(passwordEncoder.encode(newPassword));
                    userRepository.save(user);
                }
            }

            // 6. Lưu profile và trả về kết quả
            return userProfileRepository.save(profile);

        } catch (Exception ex) {
            ex.printStackTrace(); // Log lỗi server
            throw new RuntimeException("Failed to update profile: " + ex.getMessage());
        }
    }
}