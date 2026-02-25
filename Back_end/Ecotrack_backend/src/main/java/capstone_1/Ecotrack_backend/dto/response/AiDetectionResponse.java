package capstone_1.Ecotrack_backend.dto.response;

import com.fasterxml.jackson.annotation.JsonProperty;

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

        @JsonProperty("total_objects_detected")
        private int totalObjectsDetected;

        @JsonProperty("type_percentage")
        private Map<String, Double> typePercentage;

        @JsonProperty("output_image")
        private String outputImage;

        // Getters Setters
        public boolean isWaste() {
            return isWaste;
        }

        public void setWaste(boolean waste) {
            isWaste = waste;
        }

        public double getOverallConfidence() {
            return overallConfidence;
        }

        public void setOverallConfidence(double overallConfidence) {
            this.overallConfidence = overallConfidence;
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