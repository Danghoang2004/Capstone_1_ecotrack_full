package capstone_1.Ecotrack_backend.dto.response;

public class DashboardRecentActivityDto {

    private String actionType;
    private String title;
    private String createdAt;

    public DashboardRecentActivityDto() {
    }

    public DashboardRecentActivityDto(String actionType, String title, String createdAt) {
        this.actionType = actionType;
        this.title = title;
        this.createdAt = createdAt;
    }

    public String getActionType() {
        return actionType;
    }

    public void setActionType(String actionType) {
        this.actionType = actionType;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(String createdAt) {
        this.createdAt = createdAt;
    }
}