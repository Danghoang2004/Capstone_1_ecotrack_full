package capstone_1.Ecotrack_backend.dto.response;

public class MonthlyActivityDto {

    private String month; // T1, T2, T3...
    private long users; // activeUsers
    private long reports; // wasteReports
    private long campaigns; // campaigns

    public MonthlyActivityDto(String month, long users, long reports, long campaigns) {
        this.month = month;
        this.users = users;
        this.reports = reports;
        this.campaigns = campaigns;
    }

    // === GETTERS ===
    public String getMonth() {
        return month;
    }

    public long getUsers() {
        return users;
    }

    public long getReports() {
        return reports;
    }

    public long getCampaigns() {
        return campaigns;
    }

    // === SETTERS (nếu cần) ===
    public void setMonth(String month) {
        this.month = month;
    }

    public void setUsers(long users) {
        this.users = users;
    }

    public void setReports(long reports) {
        this.reports = reports;
    }

    public void setCampaigns(long campaigns) {
        this.campaigns = campaigns;
    }
}
