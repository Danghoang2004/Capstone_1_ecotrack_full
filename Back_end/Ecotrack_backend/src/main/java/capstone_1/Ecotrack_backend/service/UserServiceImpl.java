
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

        Role userRole = roleRepository.findByName("ROLE_USER")
                .orElseGet(() -> roleRepository.save(new Role("ROLE_USER")));
        user.setRoles(Collections.singleton(userRole));

        // 🔥 SAVE user trước để có user_id
        User savedUser = userRepository.save(user);

        // 🔥 TỰ TẠO PROFILE MẶC ĐỊNH
        UserProfile profile = new UserProfile();
        profile.setUser(savedUser);
        profile.setAvatarUrl("default_avatar.png");
        userProfileRepository.save(profile);

        // 🔥 TẠO USER_POINTS
        UserPoints points = new UserPoints();
        points.setUser(savedUser);
        points.setPoints(0);
        userPointsRepository.save(points);

        return savedUser;
    }


}
