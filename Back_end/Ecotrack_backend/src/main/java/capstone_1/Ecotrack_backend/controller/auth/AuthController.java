package capstone_1.Ecotrack_backend.controller.auth;

import capstone_1.Ecotrack_backend.dto.request.LoginRequest;
import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.dto.response.AuthResponse;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.security.JwtUtil;
import capstone_1.Ecotrack_backend.service.UserService;
import capstone_1.Ecotrack_backend.service.UserServiceImpl;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.Optional;

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

    @PostMapping("/register")
    public ResponseEntity<?> register(@RequestBody RegisterRequest request) {
        try {
            User user = userService.registerUser(request);
            String token = jwtUtil.generateToken(user.getUsername());
            return ResponseEntity.ok(new AuthResponse(token));
        } catch (RuntimeException ex) {
            return ResponseEntity.badRequest().body(
                    java.util.Map.of("error", ex.getMessage())
            );
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody LoginRequest request){
        try {
            Optional<User> optional = userRepository.findByEmail(request.getEmail());
            if(optional.isEmpty()){
                return ResponseEntity.status(401).body(Map.of("error", "Email không tồn tại"));
            }
            User user = optional.get();

            // Kiểm tra password
            if (!passwordEncoder.matches(request.getPassword(), user.getPassword())) {
                return ResponseEntity.status(401).body(Map.of("error", " Sai mật khẩu , vui lòng thử lại "));
            }

            if (!user.isVerified()) {
                return ResponseEntity.status(401).body(Map.of("error", "Tài khoản chưa được xác thực email"));
            }
            // Sinh JWT
            String token = jwtUtil.generateToken(user.getUsername());

            return ResponseEntity.ok(new AuthResponse(token));

        }catch(Exception e){
            return ResponseEntity.status(500).body(Map.of("error","Lỗi đăng nhập : "+e.getMessage()));
        }
    }

    @PostMapping("/verify")
    public ResponseEntity<?> verifyAccount(@RequestBody Map<String, String> request){
        String email = request.get("email");
        String code = request.get("code");

        boolean success = userServiceiml.verifyAccount(email,code);

        if(success) {

            // Lấy user để tạo token
            User user = userRepository.findByEmail(email).get();
            String token = jwtUtil.generateToken(user.getUsername());

            return ResponseEntity.ok(Map.of(
                    "message", "Xác thực tài khoản thành công!",
                    "token", token
            ));
        }

        return ResponseEntity.badRequest().body(Map.of("error", "Mã xác thực không hợp lệ"));
    }


}
