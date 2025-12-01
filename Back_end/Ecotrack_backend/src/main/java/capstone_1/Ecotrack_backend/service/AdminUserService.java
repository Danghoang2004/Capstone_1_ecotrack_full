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
        // Lấy tất cả user_points sắp xếp theo points giảm dần
        List<UserPoints> userPointsList = userPointsRepository.findAll()
                .stream()
                .sorted((a, b) -> Integer.compare(b.getPoints(), a.getPoints()))
                .collect(Collectors.toList());

        // Filter chỉ lấy users có role ROLE_USER (không lấy ROLE_ADMIN) và tạo response
        List<GetAllUserResponse> userResponses = userPointsList.stream()
                .map(userPoints -> {
                    User user = userRepository.findById(userPoints.getUserId())
                            .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userPoints.getUserId()));

                    // Chỉ lấy users có role ROLE_USER, bỏ qua ROLE_ADMIN
                    boolean isUserRole = user.getRoles().stream()
                            .anyMatch(role -> "ROLE_USER".equals(role.getName()));

                    if (!isUserRole) {
                        return null; // Skip admin users
                    }

                    UserProfile profile = user.getUserProfile();

                    // Lấy số reports
                    Long reportCount = wasteReportRepository.countByUserId(user.getId());

                    // Lấy số campaigns (groups)
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
                    response.setPoints(userPoints.getPoints());
                    response.setReports(reportCount.intValue());
                    response.setCampaigns(campaignCount.intValue());
                    response.setIsActive(user.getEnabled() != null ? user.getEnabled() : true);

                    return response;
                })
                .filter(response -> response != null) // Loại bỏ null (admin users)
                .collect(Collectors.toList());

        // Tính rank sau khi filter (rank dựa trên thứ tự trong danh sách đã filter)
        return IntStream.range(0, userResponses.size())
                .mapToObj(index -> {
                    GetAllUserResponse response = userResponses.get(index);
                    response.setRank(index + 1); // Cập nhật rank
                    return response;
                })
                .collect(Collectors.toList());
    }

    @Transactional
    public void updateUser(Long userId, UpdateUserRequest request) {
        // Tìm user
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userId));

        // Kiểm tra user có phải ROLE_USER không (không cho sửa admin)
        boolean isUserRole = user.getRoles().stream()
                .anyMatch(role -> "ROLE_USER".equals(role.getName()));
        if (!isUserRole) {
            throw new RuntimeException("Không thể chỉnh sửa tài khoản admin");
        }

        // Cập nhật thông tin User
        boolean credentialsChanged = false;

        if (request.getEmail() != null && !request.getEmail().isEmpty()) {
            // Kiểm tra email đã tồn tại chưa (trừ chính user này)
            Optional<User> existingUser = userRepository.findByEmail(request.getEmail());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                throw new RuntimeException("Email đã tồn tại");
            }
            // Nếu email thay đổi, đánh dấu credentials đã thay đổi
            if (!request.getEmail().equals(user.getEmail())) {
                credentialsChanged = true;
            }
            user.setEmail(request.getEmail());
        }

        if (request.getUsername() != null && !request.getUsername().isEmpty()) {
            // Kiểm tra username đã tồn tại chưa (trừ chính user này)
            Optional<User> existingUser = userRepository.findByUsername(request.getUsername());
            if (existingUser.isPresent() && !existingUser.get().getId().equals(userId)) {
                throw new RuntimeException("Username đã tồn tại");
            }
            user.setUsername(request.getUsername());
        }

        if (request.getPassword() != null && !request.getPassword().isEmpty()) {
            // Hash password mới
            user.setPassword(passwordEncoder.encode(request.getPassword()));
            credentialsChanged = true; // Password thay đổi
        }

        // Nếu email hoặc password thay đổi, update lastCredentialsUpdate để invalidate token
        if (credentialsChanged) {
            user.setLastCredentialsUpdate(java.time.LocalDateTime.now());
        }

        if (request.getIsActive() != null) {
            user.setEnabled(request.getIsActive());
        }

        userRepository.save(user);

        // Cập nhật thông tin UserProfile
        UserProfile profile = user.getUserProfile();
        if (profile == null) {
            // Nếu chưa có profile, tạo mới
            profile = new UserProfile();
            profile.setUser(user);
            user.setUserProfile(profile);
        }

        if (request.getFullName() != null) {
            profile.setFullName(request.getFullName());
        }

        userProfileRepository.save(profile);
    }

    @Transactional
    public void deleteUser(Long userId) {
        // Tìm user
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("Không tìm thấy user với id: " + userId));

        // Kiểm tra user có phải ROLE_USER không (không cho xóa admin)
        boolean isUserRole = user.getRoles().stream()
                .anyMatch(role -> "ROLE_USER".equals(role.getName()));
        if (!isUserRole) {
            throw new RuntimeException("Không thể xóa tài khoản admin");
        }

        // Xóa tất cả dữ liệu liên quan đến user (theo thứ tự để tránh foreign key constraint)

        // 1. Xóa PointTransaction
        pointTransactionRepository.deleteByUser(user);

        // 2. Xóa UserBadge
        userBadgeRepository.deleteByUser(user);

        // 3. Xóa Leaderboard
        leaderboardRepository.deleteByUser(user);

        // 4. Xóa GroupMember
        groupMemberRepository.deleteByUserId(userId);

        // 5. Xóa WasteReport
        wasteReportRepository.deleteByUserId(userId);

        // 6. Xóa UserPoints
        Optional<UserPoints> userPoints = userPointsRepository.findById(userId);
        userPoints.ifPresent(userPointsRepository::delete);

        // 7. Xóa UserProfile
        UserProfile profile = user.getUserProfile();
        if (profile != null) {
            userProfileRepository.delete(profile);
        }

        // 8. Xóa User (sẽ tự động xóa user_role relationship do cascade)
        userRepository.delete(user);
    }

    @Transactional
    public void deleteUsers(List<Long> userIds) {
        for (Long userId : userIds) {
            try {
                deleteUser(userId);
            } catch (RuntimeException e) {
                // Log error nhưng tiếp tục xóa các user khác
                System.err.println("Lỗi khi xóa user " + userId + ": " + e.getMessage());
            }
        }
    }
}

