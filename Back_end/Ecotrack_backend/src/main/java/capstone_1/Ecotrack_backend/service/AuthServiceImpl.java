package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AuthResponse;
import capstone_1.Ecotrack_backend.dto.response.FacebookUserInfo;
import capstone_1.Ecotrack_backend.dto.response.AuthResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import capstone_1.Ecotrack_backend.security.JwtUtil;

import java.util.*;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AuthServiceImpl implements AuthService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoderWrapper;
    private final UserProfileRepository userProfileRepository;
    private final UserPointsRepository userPointsRepository;
    private final JwtUtil jwtUtil;

    @Override
    @Transactional
    public AuthResponse loginWithFacebook(String fbToken) {
        // 1. GỌI GRAPH API CỦA FACEBOOK
        // Gửi token nhận từ Flutter lên máy chủ Facebook để xác thực và xin thông tin
        RestTemplate restTemplate = new RestTemplate();
        String fbUrl = "https://graph.facebook.com/me?fields=id,name,email&access_token=" + fbToken;
        
        FacebookUserInfo fbUser = restTemplate.getForObject(fbUrl, FacebookUserInfo.class);

        // Kiểm tra xem Facebook có trả về email hợp lệ không
        if (fbUser == null || fbUser.getEmail() == null) {
            throw new RuntimeException("Không thể lấy thông tin từ Facebook hoặc tài khoản FB chưa có email.");
        }

        // 2. KIỂM TRA DB XEM USER ĐÃ TỒN TẠI CHƯA
        Optional<User> optionalUser = userRepository.findByEmail(fbUser.getEmail());
        User user;

        if (optionalUser.isPresent()) {
            user = optionalUser.get();
            // Nếu user đã tồn tại (đăng ký qua form thường trước đó) nhưng chưa có ID Facebook
            if (user.getProviderId() == null) {
                user.setProviderId(fbUser.getId());
                userRepository.save(user);
            }
        } else {
            // 3. TẠO MỚI TÀI KHOẢN HOÀN TOÀN TỰ ĐỘNG
            user = new User();
            user.setEmail(fbUser.getEmail());
            
            // Xử lý tạo username không trùng lặp (Ví dụ: nguyenvan_1a2b3)
            String baseUsername = fbUser.getName().replaceAll("\\s+", "").toLowerCase();
            user.setUsername(baseUsername + "_" + UUID.randomUUID().toString().substring(0, 5));
            
            // Tạo mật khẩu ngẫu nhiên mã hóa (Vì đăng nhập FB không cần mật khẩu)
            user.setPassword(passwordEncoderWrapper.encode(UUID.randomUUID().toString()));
            
            // Lưu ID của Facebook và cập nhật trạng thái hoạt động
            user.setProviderId(fbUser.getId());
            user.setVerified(true); // FB đã xác thực email
            user.setEnabled(true);
            user.setAccountNonExpired(true);
            user.setAccountNonLocked(true);
            user.setCredentialsNonExpired(true);

            // Gán quyền ROLE_USER mặc định
            Role userRole = roleRepository.findByName("ROLE_USER")
                    .orElseGet(() -> roleRepository.save(new Role("ROLE_USER")));
            user.setRoles(Collections.singleton(userRole));

            // Lưu User vào bảng 'users'
            User savedUser = userRepository.save(user);

            // --- Tự động tạo dữ liệu liên kết ---
            
            // Tạo Profile lấy tên thật từ Facebook
            UserProfile profile = new UserProfile();
            profile.setUser(savedUser);
            profile.setFullName(fbUser.getName());
            profile.setAvatarUrl("default_avatar.png");
            userProfileRepository.save(profile);

            // Tạo điểm mặc định (0 điểm)
            UserPoints points = new UserPoints();
            points.setUser(savedUser);
            points.setPoints(0);
            userPointsRepository.save(points);
        }

        String jwt = jwtUtil.generateToken(user);

        // Lấy danh sách Roles để gói vào response
        List<String> roles = user.getRoles().stream()
                .map(Role::getName)
                .collect(Collectors.toList());

        // 5. TRẢ KẾT QUẢ VỀ (Khớp với Map['token', 'username', 'email', 'roles'] bên Flutter)
        return new AuthResponse(jwt, user.getUsername(), user.getEmail(), roles);
    }
}