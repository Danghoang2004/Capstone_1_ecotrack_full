
package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import java.util.*;

@Service
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final PasswordEncoder passwordEncoderWrapper;
    private final UserPointsRepository userPointsRepository;
    private final UserProfileRepository userProfileRepository;
    private final EmailServiceImp emailServiceImp;

    @Override
    @Transactional
    public User registerUser(RegisterRequest request) {

        if (userRepository.existsByUsername(request.getUsername()))
            throw new RuntimeException("Tên đăng nhập đã được sử dụng");

        if (userRepository.existsByEmail(request.getEmail()))
            throw new RuntimeException("Email đã được sử dụng");

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        user.setPassword(passwordEncoderWrapper.encode(request.getPassword()));

        // ROLE_USER mặc định
        Role userRole = roleRepository.findByName("ROLE_USER")
                .orElseGet(() -> roleRepository.save(new Role("ROLE_USER")));
        user.setRoles(Collections.singleton(userRole));

        // Tạo mã xác thực
        String otp = generateVerificationCode();
        user.setVerificationCode(otp);
        user.setVerified(false);

        User savedUser = userRepository.save(user);

        // Tạo profile
        UserProfile profile = new UserProfile();
        profile.setUser(savedUser);
        profile.setAvatarUrl("default_avatar.png");
        userProfileRepository.save(profile);

        // Tạo điểm
        UserPoints points = new UserPoints();
        points.setUser(savedUser); // Với @MapsId, userId sẽ tự động được set từ user.getId()
        points.setPoints(0);
        userPointsRepository.save(points);

        // Gửi email OTP
        guiEmailXacThuc(user.getEmail(), otp);

        return savedUser;
    }


    private String generateVerificationCode() {
        return String.valueOf(new Random().nextInt(900000) + 100000);
    }


    public void guiEmailXacThuc(String email, String code) {
        String subject = "Mã xác thực tài khoản EcoTrack";
        String text = """
                    <html>
                        <body>
                            <h3>Xin chào,</h3>
                            <p>Mã xác thực tài khoản của bạn là:</p>
                            <h2 style='color: green;'>%s</h2>
                            <p>Vui lòng nhập mã này để kích hoạt tài khoản.</p>
                        </body>
                    </html>
                """.formatted(code);

        emailServiceImp.sendMessage(
                "dangvanhoang25121984@gmail.com",
                email,
                subject,
                text);
    }


    @Transactional
    public boolean verifyAccount(String email, String code) {
        Optional<User> optional = userRepository.findByEmail(email);
        if (optional.isEmpty())
            return false;

        User user = optional.get();

        if (user.getVerificationCode() == null)
            return false;

        if (!user.getVerificationCode().equals(code))
            return false;

        user.setVerified(true);
        user.setVerificationCode(null);
        userRepository.save(user);

        return true;
    }
}
