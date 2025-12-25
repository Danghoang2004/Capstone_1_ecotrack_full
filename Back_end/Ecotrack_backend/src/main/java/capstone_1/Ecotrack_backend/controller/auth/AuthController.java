package capstone_1.Ecotrack_backend.controller.auth;

import capstone_1.Ecotrack_backend.dto.request.LoginRequest;
import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.dto.response.AuthResponse;
import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.Role;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.model.UserProfile;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.RoleRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserProfileRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.security.JwtUtil;
import capstone_1.Ecotrack_backend.service.UserService;
import capstone_1.Ecotrack_backend.service.UserServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.Random;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*") // adjust for production to specific origins
public class AuthController {

    @Autowired
    private UserService userService;

    @Autowired
    private UserServiceImpl userServiceiml;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtUtil jwtUtil;

    @Autowired
    private UserPointsRepository userPointsRepository;

    @Autowired
    private PointTransactionRepository pointTransactionRepository;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            User user = userService.registerUser(request);

            // Tặng điểm random khi đăng ký lần đầu (0-100 điểm)
            try {
                // Random điểm từ 0 đến 100
                Random random = new Random();
                int bonusPoints = random.nextInt(101); // 0-100

                // Tạo PointTransaction
                PointTransaction tx = new PointTransaction();
                tx.setUser(user);
                tx.setActionType(PointTransaction.ActionType.OTHER);
                tx.setDescription("Quà tặng đăng ký lần đầu");
                tx.setPoints(bonusPoints);
                tx.setCreatedAt(LocalDateTime.now());
                pointTransactionRepository.save(tx);

                // Cộng điểm cho user (user_points đã được tạo trong registerUser với điểm = 0)
                Optional<UserPoints> userPointsOpt = userPointsRepository.findById(user.getId());
                if (userPointsOpt.isPresent()) {
                    UserPoints userPoints = userPointsOpt.get();
                    userPoints.setPoints(userPoints.getPoints() + bonusPoints);
                    userPointsRepository.save(userPoints);
                }
            } catch (Exception e) {
                // Log lỗi nhưng không làm gián đoạn quá trình đăng ký
                System.err.println("Lỗi khi tặng điểm đăng ký: " + e.getMessage());
                e.printStackTrace();
            }

            String token = jwtUtil.generateToken(user);

            // --- CẬP NHẬT: Trả về đầy đủ thông tin giống Login ---
            // Mặc định khi đăng ký mới thường là ROLE_USER (hoặc tùy logic service của bạn)
            List<String> roles = user.getRoles().stream()
                    .map(role -> role.getName())
                    .collect(Collectors.toList());

            return ResponseEntity.ok(new AuthResponse(
                    token,
                    user.getUsername(),
                    user.getEmail(),
                    roles));
            // -----------------------------------------------------

        } catch (RuntimeException ex) {
            return ResponseEntity.badRequest().body(
                    java.util.Map.of("error", ex.getMessage()));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request) {
        try {
            Optional<User> optional = userRepository.findByEmail(request.getEmail());
            if (optional.isEmpty()) {
                return ResponseEntity.status(401).body(Map.of("error", "Email không tồn tại"));
            }
            User user = optional.get();

            // Kiểm tra password
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                return ResponseEntity.status(401).body(Map.of("error", "Sai mật khẩu, vui lòng thử lại"));
            }

            if (!user.isVerified()) { // Lưu ý: Code cũ của bạn dùng isVerified, đảm bảo field này đúng tên trong
                                      // Entity
                return ResponseEntity.status(401).body(Map.of("error", "Tài khoản chưa được xác thực email"));
            }

            // Kiểm tra tài khoản có bị khóa không (enabled = false)
            if (user.getEnabled() != null && !user.getEnabled()) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "Bạn đã bị tạm dừng tài khoản, xin vui lòng liên hệ Admin để mở khóa"));
            }

            // Sinh JWT
            String token = jwtUtil.generateToken(user);

            // --- ĐOẠN CODE QUAN TRỌNG ĐƯỢC THÊM VÀO ---
            // Lấy danh sách tên Role từ User Entity
            List<String> roles = user.getRoles().stream()
                    .map(role -> role.getName()) // Giả sử trong model Role bạn có hàm getName() trả về "ROLE_ADMIN",
                                                 // "ROLE_USER"
                    .collect(Collectors.toList());

            // Trả về Token + Roles + Info
            return ResponseEntity.ok(new AuthResponse(
                    token,
                    user.getUsername(),
                    user.getEmail(),
                    roles));
            // ------------------------------------------

        } catch (Exception e) {
            e.printStackTrace(); // In lỗi ra console để debug nếu cần
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi đăng nhập: " + e.getMessage()));
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyAccount(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String code = request.get("code");

        boolean success = userServiceiml.verifyAccount(email, code);

        if (success) {

            // Lấy user để tạo token
            User user = userRepository.findByEmail(email).get();
            String token = jwtUtil.generateToken(user);

            return ResponseEntity.ok(Map.of(
                    "message", "Xác thực tài khoản thành công!",
                    "token", token));
        }

        return ResponseEntity.badRequest().body(Map.of("error", "Mã xác thực không hợp lệ"));
    }

}
