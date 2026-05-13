package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.UpdateUserRequest;
import capstone_1.Ecotrack_backend.dto.response.GetAllUserResponse;
import capstone_1.Ecotrack_backend.service.AdminUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/environment/users")
@CrossOrigin(origins = "*")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
@RequiredArgsConstructor
public class AdminEnvironmentAccountController {

    private final AdminUserService adminUserService;

    @GetMapping
    public ResponseEntity<List<GetAllUserResponse>> getAllEnvironmentUsers() {
        return ResponseEntity.ok(adminUserService.getAllEnvironmentUsers());
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateEnvironmentUser(@PathVariable Long id, @RequestBody UpdateUserRequest request) {
        try {
            adminUserService.updateEnvironmentUser(id, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật tài khoản môi trường thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteEnvironmentUser(@PathVariable Long id) {
        try {
            adminUserService.deleteEnvironmentUser(id);
            return ResponseEntity.ok(Map.of("message", "Xóa tài khoản môi trường thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/bulk/delete")
    public ResponseEntity<?> deleteEnvironmentUsers(@RequestBody Map<String, List<Long>> payload) {
        try {
            List<Long> userIds = payload.getOrDefault("userIds", List.of());
            adminUserService.deleteEnvironmentUsers(userIds);
            return ResponseEntity.ok(Map.of("message", "Xóa " + userIds.size() + " tài khoản môi trường thành công"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }
}
