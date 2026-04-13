package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.request.environment.CreateEnvironmentTeamRequest;
import capstone_1.Ecotrack_backend.dto.request.environment.UpdateEnvironmentTeamRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamKpiResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamLeadResponse;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamResponse;
import capstone_1.Ecotrack_backend.service.environment.EnvironmentTeamManagementService;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/admin/environment/teams")
@PreAuthorize("hasAuthority('ROLE_ADMIN')")
public class AdminEnvironmentTeamController {

    private final EnvironmentTeamManagementService environmentTeamManagementService;

    public AdminEnvironmentTeamController(EnvironmentTeamManagementService environmentTeamManagementService) {
        this.environmentTeamManagementService = environmentTeamManagementService;
    }

    @GetMapping
    public List<EnvironmentTeamResponse> getAllTeams() {
        return environmentTeamManagementService.getAllTeams();
    }

    @GetMapping("/environment-users")
    public List<EnvironmentTeamLeadResponse> getEnvironmentUsers() {
        return environmentTeamManagementService.getEnvironmentUsers();
    }

    @PostMapping
    public EnvironmentTeamResponse createTeam(@Valid @RequestBody CreateEnvironmentTeamRequest request) {
        return environmentTeamManagementService.createTeam(request);
    }

    @PutMapping("/{teamId}")
    public EnvironmentTeamResponse updateTeam(@PathVariable Long teamId,
            @Valid @RequestBody UpdateEnvironmentTeamRequest request) {
        return environmentTeamManagementService.updateTeam(teamId, request);
    }

    @PutMapping("/{teamId}/lead/{userId}")
    public EnvironmentTeamResponse setTeamLead(@PathVariable Long teamId, @PathVariable Long userId) {
        return environmentTeamManagementService.setTeamLead(teamId, userId);
    }

    @PostMapping("/{teamId}/members/{userId}")
    public EnvironmentTeamResponse addMember(@PathVariable Long teamId, @PathVariable Long userId) {
        return environmentTeamManagementService.addMember(teamId, userId);
    }

    @DeleteMapping("/{teamId}/members/{userId}")
    public EnvironmentTeamResponse removeMember(@PathVariable Long teamId, @PathVariable Long userId) {
        return environmentTeamManagementService.removeMember(teamId, userId);
    }

    @GetMapping("/kpi")
    public List<EnvironmentTeamKpiResponse> getTeamKpi(
            @RequestParam(required = false) String fromAt,
            @RequestParam(required = false) String toAt) {
        return environmentTeamManagementService.getTeamKpis(fromAt, toAt);
    }
}
