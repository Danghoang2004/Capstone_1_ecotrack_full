package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.UpdateUserRequest;
import capstone_1.Ecotrack_backend.dto.response.GetAllUserResponse;
import capstone_1.Ecotrack_backend.model.*;
import capstone_1.Ecotrack_backend.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;
import java.util.stream.IntStream;

@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserRepository userRepository;
    private final UserPointsRepository userPointsRepository;
    private final UserProfileRepository userProfileRepository;
    private final WasteReportRepository wasteReportRepository;
    private final GroupMemberRepository groupMemberRepository;
    private final PointTransactionRepository pointTransactionRepository;
    private final UserBadgeRepository userBadgeRepository;
    private final LeaderboardRepository leaderboardRepository;
    private final PasswordEncoder passwordEncoder;

    @Transactional(readOnly = true)
    public List<GetAllUserResponse> getAllUsers() {
        return getUsersByRole("ROLE_USER");
    }

    @Transactional(readOnly = true)
    public List<GetAllUserResponse> getAllEnvironmentUsers() {
        return getUsersByRole("ROLE_ENVIRONMENT");
    }

    @Transactional
    public void updateUser(Long userId, UpdateUserRequest request) {
        updateUserByRole(userId, request, "ROLE_USER", "Không thể chỉnh sửa tài khoản người dùng");
    }

    @Transactional
    public void updateEnvironmentUser(Long userId, UpdateUserRequest request) {
        updateUserByRole(userId, request, "ROLE_ENVIRONMENT", "Không thể chỉnh sửa tài khoản môi trường");
    }

    @Transactional
    public void deleteUser(Long userId) {
        deleteUserByRole(userId, "ROLE_USER", "Không thể xóa tài khoản người dùng");
    }

    @Transactional
    public void deleteEnvironmentUser(Long userId) {
        deleteUserByRole(userId, "ROLE_ENVIRONMENT", "Không thể xóa tài khoản môi trường");
    }

    @Transactional
    public void deleteUsers(List<Long> userIds) {
        deleteUsersByRole(userIds, "ROLE_USER");
    }

    @Transactional
    public void deleteEnvironmentUsers(List<Long> userIds) {
        deleteUsersByRole(userIds, "ROLE_ENVIRONMENT");
    }

    private List<GetAllUserResponse> getUsersByRole(String roleName) {
        List<User> users = userRepository.findAll().stream()
                .filter(user -> hasRole(user, roleName))
                .toList();

        List<GetAllUserResponse> userResponses = users.stream()
                .map(this::buildUserResponse)
                .collect(Collectors.toList());

        userResponses.sort((a, b) -> Integer.compare(
                b.getPoints() != null ? b.getPoints() : 0,
                a.getPoints() != null ? a.getPoints() : 0));

        return IntStream.range(0, userResponses.size())
                .mapToObj(index -> {
                    GetAllUserResponse response = userResponses.get(index);
                    response.setRank(index + 1);
                    return response;
                })
                .collect(Collectors.toList());
    }

    private void updateUserByRole(Long userId, UpdateUserRequest request, String roleName, String roleErrorMessage) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userId));

        if (!hasRole(user, roleName)) {
            throw new RuntimeException(roleErrorMessage);
        }

        boolean credentialsChanged = false;

        if (request.getEmail() != null && !request.getEmail().isEmpty()) {
            Optional<User> existingUser = userRepository.findByEmail(request.getEmail());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                throw new RuntimeException("Email đã tồn tại");
            }
            if (!request.getEmail().equals(user.getEmail())) {
                credentialsChanged = true;
            }
            user.setEmail(request.getEmail());
        }

        if (request.getUsername() != null && !request.getUsername().isEmpty()) {
            Optional<User> existingUser = userRepository.findByUsername(request.getUsername());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                throw new RuntimeException("Username đã tồn tại");
            }
            user.setUsername(request.getUsername());
        }

        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            credentialsChanged = true;
        }

        if (credentialsChanged) {
            user.setLastCredentialsUpdate(java.time.LocalDateTime.now());
        }

        if (request.getIsActive() != null) {
            user.setEnabled(request.getIsActive());
        }

        userRepository.save(user);

        UserProfile profile = user.getUserProfile();
        if (profile == null) {
            profile = new UserProfile();
            profile.setUser(user);
            user.setUserProfile(profile);
        }

        if (request.getFullName() != null) {
            profile.setFullName(request.getFullName());
        }

        userProfileRepository.save(profile);
    }

    private void deleteUserByRole(Long userId, String roleName, String roleErrorMessage) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userId));

        if (!hasRole(user, roleName)) {
            throw new RuntimeException(roleErrorMessage);
        }

        pointTransactionRepository.deleteByUser(user);
        userBadgeRepository.deleteByUser(user);
        leaderboardRepository.deleteByUser(user);
        groupMemberRepository.deleteByUserId(userId);
        wasteReportRepository.deleteByUserId(userId);
        Optional<UserPoints> userPoints = userPointsRepository.findById(userId);
        userPoints.ifPresent(userPointsRepository::delete);
        UserProfile profile = user.getUserProfile();
        if (profile != null) {
            userProfileRepository.delete(profile);
        }
        userRepository.delete(user);
    }

    private void deleteUsersByRole(List<Long> userIds, String roleName) {
        for (Long userId : userIds) {
            try {
                if ("ROLE_ENVIRONMENT".equals(roleName)) {
                    deleteEnvironmentUser(userId);
                } else {
                    deleteUser(userId);
                }
            } catch (RuntimeException e) {
                System.err.println("Lỗi khi xóa user " + userId + ": " + e.getMessage());
            }
        }
    }

    private GetAllUserResponse buildUserResponse(User user) {
        UserProfile profile = user.getUserProfile();
        int points = userPointsRepository.findById(user.getId())
                .map(UserPoints::getPoints)
                .orElse(0);
        Long reportCount = wasteReportRepository.countByUserId(user.getId());
        Long campaignCount = groupMemberRepository.countByUserId(user.getId());

        GetAllUserResponse response = new GetAllUserResponse();
        response.setId(user.getId());
        response.setFullName(profile != null && profile.getFullName() != null
                ? profile.getFullName()
                : user.getUsername());
        response.setEmail(user.getEmail());
        response.setUsername(user.getUsername());
        response.setAvatarUrl(profile != null ? profile.getAvatarUrl() : null);
        response.setLocation(profile != null ? profile.getLocation() : null);
        response.setPoints(points);
        response.setReports(reportCount.intValue());
        response.setCampaigns(campaignCount.intValue());
        response.setIsActive(user.getEnabled() != null ? user.getEnabled() : true);
        return response;
    }

    private boolean hasRole(User user, String roleName) {
        return user.getRoles().stream().anyMatch(role -> roleName.equals(role.getName()));
    }
}

