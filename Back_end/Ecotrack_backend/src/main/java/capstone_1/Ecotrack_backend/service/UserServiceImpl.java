package capstone_1.Ecotrack_backend.service;

import java.util.Collections;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

import capstone_1.Ecotrack_backend.dto.request.RegisterRequest;
import capstone_1.Ecotrack_backend.model.Role;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.RoleRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import jakarta.transaction.Transactional;

@Service
public class UserServiceImpl implements UserService {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private RoleRepository roleRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public User registerUser(RegisterRequest request) {
        if (userRepository.existsByUsername(request.getUsername())) {
            throw new RuntimeException("Tên đăng nhập đã được sử dụng ");
        }
        if (userRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email này đã được sử dụng");
        }

        User user = new User();
        user.setUsername(request.getUsername());
        user.setEmail(request.getEmail());
        // hash password with BCrypt
        user.setPassword(passwordEncoder.encode(request.getPassword()));
        // default role USER: ensure exists in DB
        Role userRole = roleRepository.findByName("USER")
                .orElseGet(() -> roleRepository.save(new Role("USER")));
        user.setRoles(Collections.singleton(userRole));
        return userRepository.save(user);
    }

}