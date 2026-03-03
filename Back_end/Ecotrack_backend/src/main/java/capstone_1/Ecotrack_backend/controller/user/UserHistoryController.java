package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.UserHistoryResponse;
import capstone_1.Ecotrack_backend.service.UserHistoryService;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/user/history")
@RequiredArgsConstructor
public class UserHistoryController {

    private final UserHistoryService historyService;

    @GetMapping("/points")
    public ResponseEntity<Page<UserHistoryResponse>> getPointHistory(
            HttpServletRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Long userId = (Long) request.getAttribute("userId");

        return ResponseEntity.ok(
                historyService.getPointHistory(userId, PageRequest.of(page, size)));
    }

    @GetMapping("/reports")
    public ResponseEntity<Page<UserHistoryResponse>> getReportHistory(
            HttpServletRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Long userId = (Long) request.getAttribute("userId");

        return ResponseEntity.ok(
                historyService.getReportHistory(userId, PageRequest.of(page, size)));
    }

    @GetMapping("/quiz")
    public ResponseEntity<Page<UserHistoryResponse>> getQuizHistory(
            HttpServletRequest request,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) {

        Long userId = (Long) request.getAttribute("userId");

        return ResponseEntity.ok(
                historyService.getQuizHistory(userId, PageRequest.of(page, size)));
    }
}