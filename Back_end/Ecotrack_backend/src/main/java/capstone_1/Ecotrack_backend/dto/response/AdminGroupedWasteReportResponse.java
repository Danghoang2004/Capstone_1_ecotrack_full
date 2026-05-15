package capstone_1.Ecotrack_backend.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class AdminGroupedWasteReportResponse {
    private Long reportId;
    private String title;
    private String description;
    private String imageUrl;
    private BigDecimal gpsLat;
    private BigDecimal gpsLong;
    private String status;
    private LocalDateTime createdAt;
    private String category;
    private Double aiConfidence;
    private Integer reportCount;
    private List<ReporterInfo> reporters = new ArrayList<>();

    public Long getReportId() {
        return reportId;
    }

    public void setReportId(Long reportId) {
        this.reportId = reportId;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public BigDecimal getGpsLat() {
        return gpsLat;
    }

    public void setGpsLat(BigDecimal gpsLat) {
        this.gpsLat = gpsLat;
    }

    public BigDecimal getGpsLong() {
        return gpsLong;
    }

    public void setGpsLong(BigDecimal gpsLong) {
        this.gpsLong = gpsLong;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Double getAiConfidence() {
        return aiConfidence;
    }

    public void setAiConfidence(Double aiConfidence) {
        this.aiConfidence = aiConfidence;
    }

    public Integer getReportCount() {
        return reportCount;
    }

    public void setReportCount(Integer reportCount) {
        this.reportCount = reportCount;
    }

    public List<ReporterInfo> getReporters() {
        return reporters;
    }

    public void setReporters(List<ReporterInfo> reporters) {
        this.reporters = reporters;
    }

    public static class ReporterInfo {
        private Long userId;
        private String username;
        private String email;
        private Integer reportCount;
        private LocalDateTime latestReportedAt;

        public Long getUserId() {
            return userId;
        }

        public void setUserId(Long userId) {
            this.userId = userId;
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

        public Integer getReportCount() {
            return reportCount;
        }

        public void setReportCount(Integer reportCount) {
            this.reportCount = reportCount;
        }

        public LocalDateTime getLatestReportedAt() {
            return latestReportedAt;
        }

        public void setLatestReportedAt(LocalDateTime latestReportedAt) {
            this.latestReportedAt = latestReportedAt;
        }
    }
}
