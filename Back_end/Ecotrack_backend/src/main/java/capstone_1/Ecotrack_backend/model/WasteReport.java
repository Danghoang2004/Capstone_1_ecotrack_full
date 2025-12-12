package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "waste_reports")
public class WasteReport {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "report_id")
    private Long reportId;

    @Column(name = "user_id")
    private Long userId;

    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(name = "gps_lat", precision = 10, scale = 6)
    private BigDecimal gpsLat;

    @Column(name = "gps_long", precision = 10, scale = 6)
    private BigDecimal gpsLong;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "category")
    private String category;

    @Enumerated(EnumType.STRING)
    private Status status;

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    @Column(name = "ai_verified")
    private Boolean aiVerified;

    @Column(name = "ai_confidence")
    private Double aiConfidence;

    @Column(name = "ai_analysis_json", columnDefinition = "TEXT")
    private String aiAnalysisJson;

    @Column(name = "ai_analyzed_image_url")
    private String aiAnalyzedImageUrl;

    public enum Status {
        PENDING, VERIFIED, REJECTED, CLEANED
    }

    public WasteReport() {
    }

    public WasteReport(Long reportId, Long userId, String title, String description, BigDecimal gpsLat, String imageUrl, BigDecimal gpsLong, String category, Status status, LocalDateTime createdAt, Boolean aiVerified, Double aiConfidence, String aiAnalysisJson, String aiAnalyzedImageUrl) {
        this.reportId = reportId;
        this.userId = userId;
        this.title = title;
        this.description = description;
        this.gpsLat = gpsLat;
        this.imageUrl = imageUrl;
        this.gpsLong = gpsLong;
        this.category = category;
        this.status = status;
        this.createdAt = createdAt;
        this.aiVerified = aiVerified;
        this.aiConfidence = aiConfidence;
        this.aiAnalysisJson = aiAnalysisJson;
        this.aiAnalyzedImageUrl = aiAnalyzedImageUrl;
    }

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

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public Status getStatus() {
        return status;
    }

    public void setStatus(Status status) {
        this.status = status;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
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

    public String getAiAnalysisJson() {
        return aiAnalysisJson;
    }

    public void setAiAnalysisJson(String aiAnalysisJson) {
        this.aiAnalysisJson = aiAnalysisJson;
    }

    public String getAiAnalyzedImageUrl() {
        return aiAnalyzedImageUrl;
    }

    public void setAiAnalyzedImageUrl(String aiAnalyzedImageUrl) {
        this.aiAnalyzedImageUrl = aiAnalyzedImageUrl;
    }
}
