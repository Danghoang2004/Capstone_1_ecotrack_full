package capstone_1.Ecotrack_backend.dto.response;

import java.util.List;
import java.util.Map;

public class AiWasteClassificationResultDto {

    private boolean trashDetected;
    private double overallConfidence;
    private int totalObjectsDetected;
    private Map<String, Double> wasteTypes;
    private List<DetectionDto> detections;
    private String analyzedImagePath;

    public boolean isTrashDetected() {
        return trashDetected;
    }

    public void setTrashDetected(boolean trashDetected) {
        this.trashDetected = trashDetected;
    }

    public double getOverallConfidence() {
        return overallConfidence;
    }

    public void setOverallConfidence(double overallConfidence) {
        this.overallConfidence = overallConfidence;
    }

    public int getTotalObjectsDetected() {
        return totalObjectsDetected;
    }

    public void setTotalObjectsDetected(int totalObjectsDetected) {
        this.totalObjectsDetected = totalObjectsDetected;
    }

    public Map<String, Double> getWasteTypes() {
        return wasteTypes;
    }

    public void setWasteTypes(Map<String, Double> wasteTypes) {
        this.wasteTypes = wasteTypes;
    }

    public List<DetectionDto> getDetections() {
        return detections;
    }

    public void setDetections(List<DetectionDto> detections) {
        this.detections = detections;
    }

    public String getAnalyzedImagePath() {
        return analyzedImagePath;
    }

    public void setAnalyzedImagePath(String analyzedImagePath) {
        this.analyzedImagePath = analyzedImagePath;
    }

    public static class DetectionDto {
        private String classNameVietnamese;
        private String classNameRaw;
        private double confidence;

        public String getClassNameVietnamese() {
            return classNameVietnamese;
        }

        public void setClassNameVietnamese(String classNameVietnamese) {
            this.classNameVietnamese = classNameVietnamese;
        }

        public String getClassNameRaw() {
            return classNameRaw;
        }

        public void setClassNameRaw(String classNameRaw) {
            this.classNameRaw = classNameRaw;
        }

        public double getConfidence() {
            return confidence;
        }

        public void setConfidence(double confidence) {
            this.confidence = confidence;
        }
    }
}
