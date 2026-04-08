package capstone_1.Ecotrack_backend.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public class ClassificationHistoryDetailDto {

    private Long historyId;
    private Boolean trashDetected;
    private Double overallConfidence;
    private Integer totalObjectsDetected;
    private List<String> wasteTypes;
    private String wasteTypesJson;
    private List<Map<String, Object>> detections;
    private String originalImageUrl;
    private LocalDateTime createdAt;

    public ClassificationHistoryDetailDto() {
    }

    public ClassificationHistoryDetailDto(Long historyId, Boolean trashDetected, Double overallConfidence,
            Integer totalObjectsDetected, List<String> wasteTypes, String wasteTypesJson,
            List<Map<String, Object>> detections, String originalImageUrl,
            LocalDateTime createdAt) {
        this.historyId = historyId;
        this.trashDetected = trashDetected;
        this.overallConfidence = overallConfidence;
        this.totalObjectsDetected = totalObjectsDetected;
        this.wasteTypes = wasteTypes;
        this.wasteTypesJson = wasteTypesJson;
        this.detections = detections;
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

    public List<String> getWasteTypes() {
        return wasteTypes;
    }

    public void setWasteTypes(List<String> wasteTypes) {
        this.wasteTypes = wasteTypes;
    }

    public String getWasteTypesJson() {
        return wasteTypesJson;
    }

    public void setWasteTypesJson(String wasteTypesJson) {
        this.wasteTypesJson = wasteTypesJson;
    }

    public List<Map<String, Object>> getDetections() {
        return detections;
    }

    public void setDetections(List<Map<String, Object>> detections) {
        this.detections = detections;
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
