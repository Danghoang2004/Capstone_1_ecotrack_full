package capstone_1.Ecotrack_backend.dto.response.environment;

public class EnvironmentTeamLeadResponse {
    private Long userId;
    private String fullName;
    private String username;
    private String email;

    public EnvironmentTeamLeadResponse() {
    }

    public EnvironmentTeamLeadResponse(Long userId, String fullName, String username, String email) {
        this.userId = userId;
        this.fullName = fullName;
        this.username = username;
        this.email = email;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
