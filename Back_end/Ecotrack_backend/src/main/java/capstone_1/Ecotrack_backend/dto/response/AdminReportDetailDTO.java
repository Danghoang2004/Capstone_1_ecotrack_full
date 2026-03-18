package capstone_1.Ecotrack_backend.dto.response;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class AdminReportDetailDTO {
    private Long reportId;
    private Long userId;
    private String userName;
    private String userAvatar;
    private String title;
    private String description;
    private String category;
    private String status;
    private BigDecimal gpsLat;
    private BigDecimal gpsLong;
    private String imageUrl;
    private Boolean aiVerified;
    private Double aiConfidence;
    private LocalDateTime createdAt;

    public AdminReportDetailDTO() {
    }

    public AdminReportDetailDTO(Long reportId, Long userId, String userName, String userAvatar,
            String title, String description, String category, String status,
            BigDecimal gpsLat, BigDecimal gpsLong, String imageUrl,
            Boolean aiVerified, Double aiConfidence, LocalDateTime createdAt) {
        this.reportId = reportId;
        this.userId = userId;
        this.userName = userName;
        this.userAvatar = userAvatar;
        this.title = title;
        this.description = description;
        this.category = category;
        this.status = status;
        this.gpsLat = gpsLat;
        this.gpsLong = gpsLong;
        this.imageUrl = imageUrl;
        this.aiVerified = aiVerified;
        this.aiConfidence = aiConfidence;
        this.createdAt = createdAt;
    }

    // Getter & Setter
    public Long getReportId() {
        return reportId;
    }

    public void setReportId(Long reportId) {
        this.reportId = reportId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUserName() {
        return userName;
    }

    public void setUserName(String userName) {
        this.userName = userName;
    }

    public String getUserAvatar() {
        return userAvatar;
    }

    public void setUserAvatar(String userAvatar) {
        this.userAvatar = userAvatar;
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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
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

    public String getImageUrl() {
        return imageUrl;
    }

    public void setImageUrl(String imageUrl) {
        this.imageUrl = imageUrl;
    }

    public Boolean getAiVerified() {
        return aiVerified;
    }

    public void setAiVerified(Boolean aiVerified) {
        this.aiVerified = aiVerified;
    }

    public Double getAiConfidence() {
        return aiConfidence;
    }

    public void setAiConfidence(Double aiConfidence) {
        this.aiConfidence = aiConfidence;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
