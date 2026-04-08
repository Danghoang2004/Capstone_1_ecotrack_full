package capstone_1.Ecotrack_backend.dto.response;

import java.time.LocalDateTime;

public class ClassificationHistoryListItemDto {

    private Long historyId;
    private Boolean trashDetected;
    private Double overallConfidence;
    private Integer totalObjectsDetected;
    private String originalImageUrl;
    private LocalDateTime createdAt;

    public ClassificationHistoryListItemDto() {
    }

    public ClassificationHistoryListItemDto(Long historyId, Boolean trashDetected, Double overallConfidence,
            Integer totalObjectsDetected, String originalImageUrl, LocalDateTime createdAt) {
        this.historyId = historyId;
        this.trashDetected = trashDetected;
        this.overallConfidence = overallConfidence;
        this.totalObjectsDetected = totalObjectsDetected;
        this.originalImageUrl = originalImageUrl;
        this.createdAt = createdAt;
    }

    public Long getHistoryId() {
        return historyId;
    }

    public void setHistoryId(Long historyId) {
        this.historyId = historyId;
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
