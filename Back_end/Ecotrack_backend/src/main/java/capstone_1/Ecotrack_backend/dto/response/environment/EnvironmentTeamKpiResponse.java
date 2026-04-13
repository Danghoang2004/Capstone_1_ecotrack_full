package capstone_1.Ecotrack_backend.dto.response.environment;

public class EnvironmentTeamKpiResponse {

    private Long teamId;
    private String teamName;
    private String fromAt;
    private String toAt;
    private int totalAssigned;
    private int totalCompletedPending;
    private int totalResolved;
    private double completionRate;
    private Long avgResolutionMinutes;

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

    public String getFromAt() {
        return fromAt;
    }

    public void setFromAt(String fromAt) {
        this.fromAt = fromAt;
    }

    public String getToAt() {
        return toAt;
    }

    public void setToAt(String toAt) {
        this.toAt = toAt;
    }

    public int getTotalAssigned() {
        return totalAssigned;
    }

    public void setTotalAssigned(int totalAssigned) {
        this.totalAssigned = totalAssigned;
    }

    public int getTotalCompletedPending() {
        return totalCompletedPending;
    }

    public void setTotalCompletedPending(int totalCompletedPending) {
        this.totalCompletedPending = totalCompletedPending;
    }

    public int getTotalResolved() {
        return totalResolved;
    }

    public void setTotalResolved(int totalResolved) {
        this.totalResolved = totalResolved;
    }

    public double getCompletionRate() {
        return completionRate;
    }

    public void setCompletionRate(double completionRate) {
        this.completionRate = completionRate;
    }

    public Long getAvgResolutionMinutes() {
        return avgResolutionMinutes;
    }

    public void setAvgResolutionMinutes(Long avgResolutionMinutes) {
        this.avgResolutionMinutes = avgResolutionMinutes;
    }
}
