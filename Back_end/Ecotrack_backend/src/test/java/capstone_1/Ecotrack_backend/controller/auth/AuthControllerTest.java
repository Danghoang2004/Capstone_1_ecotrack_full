package capstone_1.Ecotrack_backend.controller.auth;

import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.model.PointTransaction;
import capstone_1.Ecotrack_backend.model.Role;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.repository.PointTransactionRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.security.JwtUtil;
import capstone_1.Ecotrack_backend.service.GoogleAuthService;
import capstone_1.Ecotrack_backend.service.UserService;
import capstone_1.Ecotrack_backend.service.UserServiceImpl;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.Optional;
import java.util.Set;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@ExtendWith(MockitoExtension.class)
class AuthControllerTest {

    private final ObjectMapper objectMapper = new ObjectMapper();

    private MockMvc mockMvc;

    @Mock
    private UserService userService;

    @Mock
    private UserServiceImpl userServiceiml;

    @Mock
    private UserRepository userRepository;

    @Mock
    private JwtUtil jwtUtil;

    @Mock
    private UserPointsRepository userPointsRepository;

    @Mock
    private PointTransactionRepository pointTransactionRepository;

    @Mock
    private GoogleAuthService googleAuthService;

    @InjectMocks
    private AuthController authController;

    @Test
    @DisplayName("Đăng ký thành công trả về AuthResponse với token và thông tin user")
    void register_success_returnsAuthResponse() throws Exception {
        mockMvc = MockMvcBuilders.standaloneSetup(authController).build();

        RegisterRequest request = new RegisterRequest("newuser", "newuser@example.com", "Password123!");

        User user = new User();
        user.setId(1L);
        user.setUsername("newuser");
        user.setEmail("newuser@example.com");
        user.setRoles(Set.of(new Role("ROLE_USER")));

        when(userService.registerUser(any(RegisterRequest.class))).thenReturn(user);
        when(jwtUtil.generateToken(user)).thenReturn("fake-jwt-token");
        when(userPointsRepository.findById(1L)).thenReturn(Optional.of(new UserPoints(1L, 0, user)));
        when(pointTransactionRepository.save(any(PointTransaction.class))).thenAnswer(invocation -> invocation.getArgument(0));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").value("fake-jwt-token"))
                .andExpect(jsonPath("$.username").value("newuser"))
                .andExpect(jsonPath("$.email").value("newuser@example.com"))
                .andExpect(jsonPath("$.roles[0]").value("ROLE_USER"));
    }

    @Test
    @DisplayName("Đăng ký thất bại khi service ném RuntimeException trả về 400 và message lỗi")
    void register_fail_whenServiceThrowsRuntimeException() throws Exception {
        mockMvc = MockMvcBuilders.standaloneSetup(authController).build();

        RegisterRequest request = new RegisterRequest("dupuser", "dup@example.com", "Password123!");

        when(userService.registerUser(any(RegisterRequest.class)))
                .thenThrow(new RuntimeException("Email already exists"));

        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content(objectMapper.writeValueAsString(request)))
                .andExpect(status().isBadRequest())
                .andExpect(jsonPath("$.error").value("Email already exists"));
    }
}

