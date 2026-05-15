package capstone_1.Ecotrack_backend.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

public class AiDetectionResponse {
    private boolean success;
    private AiData data;

    // Getters Setters
    public boolean isSuccess() {
        return success;
    }

    public void setSuccess(boolean success) {
        this.success = success;
    }

    public AiData getData() {
        return data;
    }

    public void setData(AiData data) {
        this.data = data;
    }

    public static class AiData {
        @JsonProperty("is_waste")
        private boolean isWaste;

        @JsonProperty("overall_confidence")
        private double overallConfidence;

        @JsonProperty("object_confidence_score")
        private Double objectConfidenceScore;

        @JsonProperty("waste_context_score")
        private Double wasteContextScore;

        @JsonProperty("final_waste_score")
        private Double finalWasteScore;

        @JsonProperty("waste_area_ratio")
        private Double wasteAreaRatio;

        @JsonProperty("object_count")
        private Integer objectCount;

        @JsonProperty("severity_score")
        private Integer severityScore;

        @JsonProperty("pollution_level")
        private String pollutionLevel;

        @JsonProperty("severity_description")
        private String severityDescription;

        @JsonProperty("recommendation")
        private String recommendation;

        @JsonProperty("ai_decision")
        private String aiDecision;

        @JsonProperty("report_status")
        private String reportStatus;

        @JsonProperty("need_manual_review")
        private Boolean needManualReview;

        @JsonProperty("error_message")
        private String errorMessage;

        @JsonProperty("image_quality_score")
        private Double imageQualityScore;

        @JsonProperty("detected_items")
        private List<String> detectedItems;

        @JsonProperty("waste_type")
        private String wasteType;

        @JsonProperty("total_objects_detected")
        private int totalObjectsDetected;

        @JsonProperty("type_percentage")
        private Map<String, Double> typePercentage;

        @JsonProperty("output_image")
        private String outputImage;

        @JsonProperty("false_positive_reason")
        private String falsePosReason;

        @JsonProperty("model_a_has_general_object")
        private Boolean modelAHasGeneralObject;

        @JsonProperty("model_a_detected_items")
        private List<String> modelADetectedItems;

        @JsonProperty("model_a_reason")
        private String modelAReason;

        @JsonProperty("model_b_detected_items")
        private List<String> modelBDetectedItems;

        @JsonProperty("final_waste_decision")
        private String finalWasteDecision;

        // Getters Setters
        public boolean isWaste() {
            return isWaste;
        }

        public void setWaste(boolean waste) {
            isWaste = waste;
        }

        public String getFalsePosReason() {
            return falsePosReason;
        }

        public void setFalsePosReason(String falsePosReason) {
            this.falsePosReason = falsePosReason;
        }

        public Boolean getModelAHasGeneralObject() {
            return modelAHasGeneralObject;
        }

        public void setModelAHasGeneralObject(Boolean modelAHasGeneralObject) {
            this.modelAHasGeneralObject = modelAHasGeneralObject;
        }

        public List<String> getModelADetectedItems() {
            return modelADetectedItems;
        }

        public void setModelADetectedItems(List<String> modelADetectedItems) {
            this.modelADetectedItems = modelADetectedItems;
        }

        public String getModelAReason() {
            return modelAReason;
        }

        public void setModelAReason(String modelAReason) {
            this.modelAReason = modelAReason;
        }

        public List<String> getModelBDetectedItems() {
            return modelBDetectedItems;
        }

        public void setModelBDetectedItems(List<String> modelBDetectedItems) {
            this.modelBDetectedItems = modelBDetectedItems;
        }

        public String getFinalWasteDecision() {
            return finalWasteDecision;
        }

        public void setFinalWasteDecision(String finalWasteDecision) {
            this.finalWasteDecision = finalWasteDecision;
        }

        public double getOverallConfidence() {
            return overallConfidence;
        }

        public void setOverallConfidence(double overallConfidence) {
            this.overallConfidence = overallConfidence;
        }

        public Double getObjectConfidenceScore() {
            return objectConfidenceScore;
        }

        public void setObjectConfidenceScore(Double objectConfidenceScore) {
            this.objectConfidenceScore = objectConfidenceScore;
        }

        public Double getWasteContextScore() {
            return wasteContextScore;
        }

        public void setWasteContextScore(Double wasteContextScore) {
            this.wasteContextScore = wasteContextScore;
        }

        public Double getFinalWasteScore() {
            return finalWasteScore;
        }

        public void setFinalWasteScore(Double finalWasteScore) {
            this.finalWasteScore = finalWasteScore;
        }

        public Double getWasteAreaRatio() {
            return wasteAreaRatio;
        }

        public void setWasteAreaRatio(Double wasteAreaRatio) {
            this.wasteAreaRatio = wasteAreaRatio;
        }

        public Integer getObjectCount() {
            return objectCount;
        }

        public void setObjectCount(Integer objectCount) {
            this.objectCount = objectCount;
        }

        public Integer getSeverityScore() {
            return severityScore;
        }

        public void setSeverityScore(Integer severityScore) {
            this.severityScore = severityScore;
        }

        public String getPollutionLevel() {
            return pollutionLevel;
        }

        public void setPollutionLevel(String pollutionLevel) {
            this.pollutionLevel = pollutionLevel;
        }

        public String getSeverityDescription() {
            return severityDescription;
        }

        public void setSeverityDescription(String severityDescription) {
            this.severityDescription = severityDescription;
        }

        public String getRecommendation() {
            return recommendation;
        }

        public void setRecommendation(String recommendation) {
            this.recommendation = recommendation;
        }

        public String getAiDecision() {
            return aiDecision;
        }

        public void setAiDecision(String aiDecision) {
            this.aiDecision = aiDecision;
        }

        public String getReportStatus() {
            return reportStatus;
        }

        public void setReportStatus(String reportStatus) {
            this.reportStatus = reportStatus;
        }

        public Boolean getNeedManualReview() {
            return needManualReview;
        }

        public void setNeedManualReview(Boolean needManualReview) {
            this.needManualReview = needManualReview;
        }

        public String getErrorMessage() {
            return errorMessage;
        }

        public void setErrorMessage(String errorMessage) {
            this.errorMessage = errorMessage;
        }

        public Double getImageQualityScore() {
            return imageQualityScore;
        }

        public void setImageQualityScore(Double imageQualityScore) {
            this.imageQualityScore = imageQualityScore;
        }

        public List<String> getDetectedItems() {
            return detectedItems;
        }

        public void setDetectedItems(List<String> detectedItems) {
            this.detectedItems = detectedItems;
        }

        public String getWasteType() {
            return wasteType;
        }

        public void setWasteType(String wasteType) {
            this.wasteType = wasteType;
        }

        public Map<String, Double> getTypePercentage() {
            return typePercentage;
        }

        public void setTypePercentage(Map<String, Double> typePercentage) {
            this.typePercentage = typePercentage;
        }

        public String getOutputImage() {
            return outputImage;
        }

        public void setOutputImage(String outputImage) {
            this.outputImage = outputImage;
        }
    }
}