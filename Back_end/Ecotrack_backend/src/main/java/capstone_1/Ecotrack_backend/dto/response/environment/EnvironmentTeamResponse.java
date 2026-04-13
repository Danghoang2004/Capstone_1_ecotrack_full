package capstone_1.Ecotrack_backend.dto.response.environment;

import java.time.LocalDateTime;
import java.util.List;

public class EnvironmentTeamResponse {

    private Long teamId;
    private String teamName;
    private String description;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private EnvironmentTeamMemberResponse lead;
    private List<EnvironmentTeamMemberResponse> members;

    public Long getTeamId() {
        return teamId;
    }

    public void setTeamId(Long teamId) {
        this.teamId = teamId;
    }

    public String getTeamName() {
        return teamName;
    }

    public void setTeamName(String teamName) {
        this.teamName = teamName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public LocalDateTime getUpdatedAt() {
        return updatedAt;
    }

    public void setUpdatedAt(LocalDateTime updatedAt) {
        this.updatedAt = updatedAt;
    }

    public EnvironmentTeamMemberResponse getLead() {
        return lead;
    }

    public void setLead(EnvironmentTeamMemberResponse lead) {
        this.lead = lead;
    }

    public List<EnvironmentTeamMemberResponse> getMembers() {
        return members;
    }

    public void setMembers(List<EnvironmentTeamMemberResponse> members) {
        this.members = members;
    }
}
