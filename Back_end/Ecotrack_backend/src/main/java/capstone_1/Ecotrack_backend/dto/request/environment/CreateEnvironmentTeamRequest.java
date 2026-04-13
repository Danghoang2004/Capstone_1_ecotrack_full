package capstone_1.Ecotrack_backend.dto.request.environment;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

import java.util.List;

public class CreateEnvironmentTeamRequest {

    @NotBlank(message = "teamName is required")
    private String teamName;

    private String description;

    @NotNull(message = "leadUserId is required")
    private Long leadUserId;

    private List<Long> memberUserIds;

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

    public Long getLeadUserId() {
        return leadUserId;
    }

    public void setLeadUserId(Long leadUserId) {
        this.leadUserId = leadUserId;
    }

    public List<Long> getMemberUserIds() {
        return memberUserIds;
    }

    public void setMemberUserIds(List<Long> memberUserIds) {
        this.memberUserIds = memberUserIds;
    }
}
