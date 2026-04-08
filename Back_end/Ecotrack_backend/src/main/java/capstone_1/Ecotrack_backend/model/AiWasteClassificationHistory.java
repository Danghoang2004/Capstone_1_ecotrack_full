package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

@Entity
@Table(name = "ai_waste_classification_history")
public class AiWasteClassificationHistory {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "history_id")
    private Long historyId;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "trash_detected", nullable = false)
    private Boolean trashDetected;

    @Column(name = "overall_confidence", nullable = false)
    private Double overallConfidence;

    @Column(name = "total_objects_detected", nullable = false)
    private Integer totalObjectsDetected;

    @Column(name = "waste_types_json", columnDefinition = "LONGTEXT")
    private String wasteTypesJson;

    @Column(name = "detections_json", columnDefinition = "LONGTEXT")
    private String detectionsJson;

    @Column(name = "raw_result_json", columnDefinition = "LONGTEXT")
    private String rawResultJson;

    @Column(name = "original_image_url", length = 500)
    private String originalImageUrl;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public Long getHistoryId() {
        return historyId;
    }

    public void setHistoryId(Long historyId) {
        this.historyId = historyId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Boolean getTrashDetected() {
        return trashDetected;
    }

    public void setTrashDetected(Boolean trashDetected) {
        this.trashDetected = trashDetected;
    }

    public Double getOverallConfidence() {
        return overallConfidence;
    }

    public void setOverallConfidence(Double overallConfidence) {
        this.overallConfidence = overallConfidence;
    }

    public Integer getTotalObjectsDetected() {
        return totalObjectsDetected;
    }

    public void setTotalObjectsDetected(Integer totalObjectsDetected) {
        this.totalObjectsDetected = totalObjectsDetected;
    }

    public String getWasteTypesJson() {
        return wasteTypesJson;
    }

    public void setWasteTypesJson(String wasteTypesJson) {
        this.wasteTypesJson = wasteTypesJson;
    }

    public String getDetectionsJson() {
        return detectionsJson;
    }

    public void setDetectionsJson(String detectionsJson) {
        this.detectionsJson = detectionsJson;
    }

    public String getRawResultJson() {
        return rawResultJson;
    }

    public void setRawResultJson(String rawResultJson) {
        this.rawResultJson = rawResultJson;
    }

    public String getOriginalImageUrl() {
        return originalImageUrl;
    }

    public void setOriginalImageUrl(String originalImageUrl) {
        this.originalImageUrl = originalImageUrl;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
