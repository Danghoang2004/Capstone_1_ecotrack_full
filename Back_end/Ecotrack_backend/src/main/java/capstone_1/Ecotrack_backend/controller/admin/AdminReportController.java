package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.response.AdminReportListResponse;
import capstone_1.Ecotrack_backend.dto.response.ApiResponse;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.service.WasteReportService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin/reports")
@CrossOrigin
public class AdminReportController {

    private final WasteReportService reportService;

    public AdminReportController(WasteReportService reportService) {
        this.reportService = reportService;
    }

    @GetMapping("")
    public ResponseEntity<List<WasteReport>> getAllReports() {
        List<WasteReport> reports = reportService.getAllReportsForAdmin();
        return ResponseEntity.ok(reports);
    }

    @PutMapping("/{id}/status")
    public ResponseEntity<?> updateStatus(@PathVariable Long id, @RequestBody Map<String, String> payload) {
        String newStatus = payload.get("status");

        if (newStatus == null) {
            return ResponseEntity.badRequest().body(Map.of("error", "Status is required"));
        }

        boolean success = reportService.updateReportStatus(id, newStatus);

        if (success) {
            return ResponseEntity.ok(Map.of("message", "Update status successfully"));
        } else {
            return ResponseEntity.badRequest().body(Map.of("error", "Update failed or Invalid status"));
        }
    }

    @GetMapping("/list-with-details")
    public ResponseEntity<ApiResponse<AdminReportListResponse>> getReportsWithDetails() {
        try {
            AdminReportListResponse response = reportService.getAllReportsWithDetails();
            return ResponseEntity.ok(
                    ApiResponse.success(
                            "200",
                            "Lấy danh sách báo cáo thành công",
                            response));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(
                    ApiResponse.error("500", "Lỗi: " + e.getMessage()));
        }
    }
}