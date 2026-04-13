package capstone_1.Ecotrack_backend.dto.response.environment;

public class EnvironmentMyTeamInfoResponse {
    private Long teamId;
    private String teamName;
    private String teamDescription;
    private String myRoleInTeam;
    private Long leadUserId;
    private String leadFullName;
    private Integer memberCount;

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

    public String getTeamDescription() {
        return teamDescription;
    }

    public void setTeamDescription(String teamDescription) {
        this.teamDescription = teamDescription;
    }

    public String getMyRoleInTeam() {
        return myRoleInTeam;
    }

    public void setMyRoleInTeam(String myRoleInTeam) {
        this.myRoleInTeam = myRoleInTeam;
    }

    public Long getLeadUserId() {
        return leadUserId;
    }

    public void setLeadUserId(Long leadUserId) {
        this.leadUserId = leadUserId;
    }

    public String getLeadFullName() {
        return leadFullName;
    }

    public void setLeadFullName(String leadFullName) {
        this.leadFullName = leadFullName;
    }

    public Integer getMemberCount() {
        return memberCount;
    }

    public void setMemberCount(Integer memberCount) {
        this.memberCount = memberCount;
    }
}
