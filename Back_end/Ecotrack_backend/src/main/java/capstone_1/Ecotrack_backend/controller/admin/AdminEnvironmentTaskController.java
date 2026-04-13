package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.environment.AssignEnvironmentTaskRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentCleanupTaskResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamLeadResponse;
import capstone_1.Ecotrack_backend.service.environment.EnvironmentCleanupService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/environment/tasks")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminEnvironmentTaskController {

    private final EnvironmentCleanupService environmentCleanupService;

    public AdminEnvironmentTaskController(EnvironmentCleanupService environmentCleanupService) {
        this.environmentCleanupService = environmentCleanupService;
    }

    @GetMapping
    public List<EnvironmentCleanupTaskResponse> getAllTasks() {
        return environmentCleanupService.getAllTasksForAdmin();
    }

    @GetMapping("/team-leads")
    public List<EnvironmentTeamLeadResponse> getEnvironmentTeamLeads() {
        return environmentCleanupService.getEnvironmentTeamLeads();
    }

    @PostMapping("/assign")
    public EnvironmentCleanupTaskResponse assignTask(@Valid @RequestBody AssignEnvironmentTaskRequest request) {
        return environmentCleanupService.assignTask(request);
    }

    @PutMapping("/{taskId}/resolve")
    public EnvironmentCleanupTaskResponse resolveTask(@PathVariable Long taskId, HttpServletRequest request) {
        Long adminUserId = (Long) request.getAttribute("userId");
        return environmentCleanupService.resolveTask(taskId, adminUserId);
    }
}
