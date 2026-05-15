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

    @Column(name = "ai_waste_type")
    private String aiWasteType;

    @Column(name = "ai_final_waste_score")
    private Double aiFinalWasteScore;

    @Column(name = "ai_waste_context_score")
    private Double aiWasteContextScore;

    @Column(name = "ai_waste_area_ratio")
    private Double aiWasteAreaRatio;

    @Column(name = "ai_object_count")
    private Integer aiObjectCount;

    @Column(name = "ai_severity_score")
    private Integer aiSeverityScore;

    @Column(name = "ai_pollution_level")
    private String aiPollutionLevel;

    @Column(name = "ai_severity_description", columnDefinition = "TEXT")
    private String aiSeverityDescription;

    @Column(name = "ai_recommendation", columnDefinition = "TEXT")
    private String aiRecommendation;

    @Column(name = "ai_decision")
    private String aiDecision;

    @Column(name = "ai_need_manual_review")
    private Boolean aiNeedManualReview;

    @Column(name = "ai_error_message", columnDefinition = "TEXT")
    private String aiErrorMessage;

    @Column(name = "ai_false_positive_reason", columnDefinition = "TEXT")
    private String aiFalsePositiveReason;

    public enum Status {
        PENDING, VERIFIED, REJECTED, CLEANED, PENDING_AI_ANALYSIS, AI_VERIFIED, NEED_REVIEW, REQUEST_REUPLOAD, APPROVED
    }

    public WasteReport() {
    }

    public WasteReport(Long reportId, Long userId, String title, String description, BigDecimal gpsLat, String imageUrl,
            BigDecimal gpsLong, String category, Status status, LocalDateTime createdAt, Boolean aiVerified,
            Double aiConfidence, String aiAnalysisJson, String aiAnalyzedImageUrl) {
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

    public String getAiWasteType() {
        return aiWasteType;
    }

    public void setAiWasteType(String aiWasteType) {
        this.aiWasteType = aiWasteType;
    }

    public Double getAiFinalWasteScore() {
        return aiFinalWasteScore;
    }

    public void setAiFinalWasteScore(Double aiFinalWasteScore) {
        this.aiFinalWasteScore = aiFinalWasteScore;
    }

    public Double getAiWasteContextScore() {
        return aiWasteContextScore;
    }

    public void setAiWasteContextScore(Double aiWasteContextScore) {
        this.aiWasteContextScore = aiWasteContextScore;
    }

    public Double getAiWasteAreaRatio() {
        return aiWasteAreaRatio;
    }

    public void setAiWasteAreaRatio(Double aiWasteAreaRatio) {
        this.aiWasteAreaRatio = aiWasteAreaRatio;
    }

    public Integer getAiObjectCount() {
        return aiObjectCount;
    }

    public void setAiObjectCount(Integer aiObjectCount) {
        this.aiObjectCount = aiObjectCount;
    }

    public Integer getAiSeverityScore() {
        return aiSeverityScore;
    }

    public void setAiSeverityScore(Integer aiSeverityScore) {
        this.aiSeverityScore = aiSeverityScore;
    }

    public String getAiPollutionLevel() {
        return aiPollutionLevel;
    }

    public void setAiPollutionLevel(String aiPollutionLevel) {
        this.aiPollutionLevel = aiPollutionLevel;
    }

    public String getAiSeverityDescription() {
        return aiSeverityDescription;
    }

    public void setAiSeverityDescription(String aiSeverityDescription) {
        this.aiSeverityDescription = aiSeverityDescription;
    }

    public String getAiRecommendation() {
        return aiRecommendation;
    }

    public void setAiRecommendation(String aiRecommendation) {
        this.aiRecommendation = aiRecommendation;
    }

    public String getAiDecision() {
        return aiDecision;
    }

    public void setAiDecision(String aiDecision) {
        this.aiDecision = aiDecision;
    }

    public Boolean getAiNeedManualReview() {
        return aiNeedManualReview;
    }

    public void setAiNeedManualReview(Boolean aiNeedManualReview) {
        this.aiNeedManualReview = aiNeedManualReview;
    }

    public String getAiErrorMessage() {
        return aiErrorMessage;
    }

    public void setAiErrorMessage(String aiErrorMessage) {
        this.aiErrorMessage = aiErrorMessage;
    }

    public String getAiFalsePositiveReason() {
        return aiFalsePositiveReason;
    }

    public void setAiFalsePositiveReason(String aiFalsePositiveReason) {
        this.aiFalsePositiveReason = aiFalsePositiveReason;
    }
}
