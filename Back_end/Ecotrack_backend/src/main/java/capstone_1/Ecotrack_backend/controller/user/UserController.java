package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.request.UpdateUserRequest;
import capstone_1.Ecotrack_backend.dto.response.GetAllUserResponse;
import capstone_1.Ecotrack_backend.service.AdminUserService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
@RequiredArgsConstructor
public class UserController {

    private final AdminUserService adminUserService;

    @GetMapping("/getAllUser")
    public ResponseEntity<List<GetAllUserResponse>> getAllUsers() {
        List<GetAllUserResponse> users = adminUserService.getAllUsers();
        return ResponseEntity.ok(users);
    }

    @PutMapping("/{id}")
    public ResponseEntity<?> updateUser(@PathVariable Long id, @RequestBody UpdateUserRequest request) {
        try {
            adminUserService.updateUser(id, request);
            return ResponseEntity.ok(Map.of("message", "Cập nhật thông tin user thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteUser(@PathVariable Long id) {
        try {
            adminUserService.deleteUser(id);
            return ResponseEntity.ok(Map.of("message", "Xóa user thành công"));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of("error", e.getMessage()));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }

    @PostMapping("/bulk/delete")
    public ResponseEntity<?> deleteUsers(@RequestBody List<Long> userIds) {
        try {
            adminUserService.deleteUsers(userIds);
            return ResponseEntity.ok(Map.of("message", "Xóa " + userIds.size() + " user thành công"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", "Lỗi server: " + e.getMessage()));
        }
    }
}

