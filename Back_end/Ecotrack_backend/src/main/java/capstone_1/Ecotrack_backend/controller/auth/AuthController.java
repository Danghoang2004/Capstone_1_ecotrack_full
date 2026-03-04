package capstone_1.Ecotrack_backend.controller.auth;

import capstone_1.Ecotrack_backend.dto.request.GoogleLoginRequest;
import capstone_1.Ecotrack_backend.dto.request.LoginRequest;
import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.dto.request.ResetPasswordRequestWithOtp;
import capstone_1.Ecotrack_backend.dto.request.VerifyOtpRequest;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.dto.response.AuthResponse;
import capstone_1.Ecotrack_backend.model.PointTransaction;

import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.security.JwtUtil;
import capstone_1.Ecotrack_backend.service.GoogleAuthService;
import capstone_1.Ecotrack_backend.service.PasswordResetOtpService;
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
@CrossOrigin(origins = "*")
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

    @Autowired
    private GoogleAuthService googleAuthService;

    @Autowired
    private PasswordResetOtpService passwordResetOtpService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            User user = userService.registerUser(request);
            try {
                Random random = new Random();
                int bonusPoints = random.nextInt(101);

                PointTransaction tx = new PointTransaction();
                tx.setUser(user);
                tx.setActionType(PointTransaction.ActionType.OTHER);
                tx.setDescription("Quà tặng đăng ký lần đầu");
                tx.setPoints(bonusPoints);
                tx.setCreatedAt(LocalDateTime.now());
                pointTransactionRepository.save(tx);

                Optional<UserPoints> userPointsOpt = userPointsRepository.findById(user.getId());
                if (userPointsOpt.isPresent()) {
                    UserPoints userPoints = userPointsOpt.get();
                    userPoints.setPoints(userPoints.getPoints() + bonusPoints);
                    userPointsRepository.save(userPoints);
                }
            } catch (Exception e) {
                System.err.println("Lỗi khi tặng điểm đăng ký: " + e.getMessage());
                e.printStackTrace();
            }
            String token = jwtUtil.generateToken(user);
            List<String> roles = user.getRoles().stream()
                    .map(role -> role.getName())
                    .collect(Collectors.toList());
            return ResponseEntity.ok(new AuthResponse(
                    token,
                    user.getUsername(),
                    user.getEmail(),
                    roles));

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

            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                return ResponseEntity.status(401).body(Map.of("error", "Sai mật khẩu, vui lòng thử lại"));
            }

            if (!user.isVerified()) {

                return ResponseEntity.status(401).body(Map.of("error", "Tài khoản chưa được xác thực email"));
            }

            if (user.getEnabled() != null && !user.getEnabled()) {
                return ResponseEntity.status(403)
                        .body(Map.of("error", "Bạn đã bị tạm dừng tài khoản, xin vui lòng liên hệ Admin để mở khóa"));
            }

            String token = jwtUtil.generateToken(user);

            List<String> roles = user.getRoles().stream()
                    .map(role -> role.getName())
                    .collect(Collectors.toList());

            return ResponseEntity.ok(new AuthResponse(
                    token,
                    user.getUsername(),
                    user.getEmail(),
                    roles));
            // ------------------------------------------

        } catch (Exception e) {
            e.printStackTrace();
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi đăng nhập: " + e.getMessage()));
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyAccount(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String code = request.get("code");
        boolean success = userServiceiml.verifyAccount(email, code);
        if (success) {
            User user = userRepository.findByEmail(email).get();
            String token = jwtUtil.generateToken(user);

            return ResponseEntity.ok(Map.of(
                    "message", "Xác thực tài khoản thành công!",
                    "token", token));
        }

        return ResponseEntity.badRequest().body(Map.of("error", "Mã xác thực không hợp lệ"));
    }

    @PostMapping("/google")
    public ResponseEntity<?> loginWithGoogle(
            @RequestBody GoogleLoginRequest request) {
        try {
            String token = googleAuthService.login(request.idToken());
            return ResponseEntity.ok(Map.of("accessToken", token));
        } catch (Exception e) {
            return ResponseEntity.status(401)
                    .body(Map.of("error", e.getMessage()));
        }
    }

    @PostMapping("/reset-password/request")
    public ResponseEntity<?> requestResetPassword(
            @RequestBody ResetPasswordRequestWithOtp request) {

        passwordResetOtpService.requestResetPassword(request);

        return ResponseEntity.ok(
                Map.of("message", "OTP đã được gửi tới email"));
    }

    @PostMapping("/reset-password/confirm")
    public ResponseEntity<ApiResponse<?>> confirmResetPassword(
            @RequestBody VerifyOtpRequest request) {

        ApiResponse<?> response = passwordResetOtpService.verifyOtpAndResetPassword(request);

        return ResponseEntity.ok(response);
    }
}
