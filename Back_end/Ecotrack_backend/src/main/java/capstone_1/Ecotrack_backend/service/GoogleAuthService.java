package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.Role;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.model.UserPoints;
import capstone_1.Ecotrack_backend.model.UserProfile;
import capstone_1.Ecotrack_backend.repository.RoleRepository;
import capstone_1.Ecotrack_backend.repository.UserPointsRepository;
import capstone_1.Ecotrack_backend.repository.UserProfileRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import capstone_1.Ecotrack_backend.security.JwtUtil;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.jackson2.JacksonFactory;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Set;
import java.util.UUID;

@Service
public class GoogleAuthService {

    @Value("${google.client-id}")
    private String googleClientId;

    private final UserRepository userRepository;
    private final RoleRepository roleRepository;
    private final UserProfileRepository userProfileRepository;
    private final UserPointsRepository userPointsRepository;
    private final JwtUtil jwtUtil;

    public GoogleAuthService(
            UserRepository userRepository,
            RoleRepository roleRepository,
            UserProfileRepository userProfileRepository,
            UserPointsRepository userPointsRepository,
            JwtUtil jwtUtil) {

        this.userRepository = userRepository;
        this.roleRepository = roleRepository;
        this.userProfileRepository = userProfileRepository;
        this.userPointsRepository = userPointsRepository;
        this.jwtUtil = jwtUtil;
    }

    public String login(String idTokenString) throws Exception {

        GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                new NetHttpTransport(),
                JacksonFactory.getDefaultInstance())
                .setAudience(List.of(googleClientId))
                .build();

        GoogleIdToken idToken = verifier.verify(idTokenString);
        if (idToken == null) {
            throw new RuntimeException("Invalid Google token");
        }

        GoogleIdToken.Payload payload = idToken.getPayload();

        String email = payload.getEmail();
        String name = (String) payload.get("name");
        String avatar = (String) payload.get("picture");
        String googleSub = payload.getSubject();

        User user = userRepository.findByEmail(email)
                .orElseGet(() -> createGoogleUser(email, name, avatar, googleSub));

        return jwtUtil.generateToken(user);
    }

    private User createGoogleUser(
            String email,
            String name,
            String avatar,
            String googleSub) {

        User user = new User();
        user.setUsername(email);
        user.setEmail(email);
        user.setPassword(UUID.randomUUID().toString());
        user.setProviderId(googleSub);
        user.setVerified(true);
        user.setEnabled(true);

        Role roleUser = roleRepository.findByName("ROLE_USER")
                .orElseThrow(() -> new RuntimeException("ROLE_USER not found"));

        user.setRoles(Set.of(roleUser));
        userRepository.save(user);

        UserProfile profile = new UserProfile();
        profile.setUser(user);
        profile.setFullName(name);
        profile.setAvatarUrl(avatar);
        userProfileRepository.save(profile);

        UserPoints points = new UserPoints();
        points.setUser(user);
        points.setPoints(0);
        userPointsRepository.save(points);

        return user;
    }
}