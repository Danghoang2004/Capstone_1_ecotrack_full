package capstone_1.Ecotrack_backend.dto.response;

public class DashboardLevelDistributionDto {

    private String level;
    private long count;

    public DashboardLevelDistributionDto() {
    }

    public DashboardLevelDistributionDto(String level, long count) {
        this.level = level;
        this.count = count;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public long getCount() {
        return count;
    }

    public void setCount(long count) {
        this.count = count;
    }
}