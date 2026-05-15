package capstone_1.Ecotrack_backend.dto.response;

import java.util.ArrayList;
import java.util.List;

public class AdminRecycleGuideResponse {
    private Long guideId;
    private String wasteTypeKey;
    private String wasteTypeLabel;
    private String name;
    private String description;
    private String imageUrl;
    private String difficultyLevel;
    private Integer estimatedTimeMinutes;
    private String materialsNeeded;
    private Boolean isActive;
    private Integer stepCount;
    private List<AdminRecycleStepResponse> steps = new ArrayList<>();

    public Long getGuideId() {
        return guideId;
    }

    public void setGuideId(Long guideId) {
        this.guideId = guideId;
    }

    public String getWasteTypeKey() {
        return wasteTypeKey;
    }

    public void setWasteTypeKey(String wasteTypeKey) {
        this.wasteTypeKey = wasteTypeKey;
    }

    public String getWasteTypeLabel() {
        return wasteTypeLabel;
    }

    public void setWasteTypeLabel(String wasteTypeLabel) {
        this.wasteTypeLabel = wasteTypeLabel;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
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

    public String getDifficultyLevel() {
        return difficultyLevel;
    }

    public void setDifficultyLevel(String difficultyLevel) {
        this.difficultyLevel = difficultyLevel;
    }

    public Integer getEstimatedTimeMinutes() {
        return estimatedTimeMinutes;
    }

    public void setEstimatedTimeMinutes(Integer estimatedTimeMinutes) {
        this.estimatedTimeMinutes = estimatedTimeMinutes;
    }

    public String getMaterialsNeeded() {
        return materialsNeeded;
    }

    public void setMaterialsNeeded(String materialsNeeded) {
        this.materialsNeeded = materialsNeeded;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public Integer getStepCount() {
        return stepCount;
    }

    public void setStepCount(Integer stepCount) {
        this.stepCount = stepCount;
    }

    public List<AdminRecycleStepResponse> getSteps() {
        return steps;
    }

    public void setSteps(List<AdminRecycleStepResponse> steps) {
        this.steps = steps;
    }

    public static class AdminRecycleStepResponse {
        private Long stepId;
        private Integer stepOrder;
        private String stepTitle;
        private String stepDescription;
        private String instructionImageUrl;
        private String instructionVideoUrl;

        public Long getStepId() {
            return stepId;
        }

        public void setStepId(Long stepId) {
            this.stepId = stepId;
        }

        public Integer getStepOrder() {
            return stepOrder;
        }

        public void setStepOrder(Integer stepOrder) {
            this.stepOrder = stepOrder;
        }

        public String getStepTitle() {
            return stepTitle;
        }

        public void setStepTitle(String stepTitle) {
            this.stepTitle = stepTitle;
        }

        public String getStepDescription() {
            return stepDescription;
        }

        public void setStepDescription(String stepDescription) {
            this.stepDescription = stepDescription;
        }

        public String getInstructionImageUrl() {
            return instructionImageUrl;
        }

        public void setInstructionImageUrl(String instructionImageUrl) {
            this.instructionImageUrl = instructionImageUrl;
        }

        public String getInstructionVideoUrl() {
            return instructionVideoUrl;
        }

        public void setInstructionVideoUrl(String instructionVideoUrl) {
            this.instructionVideoUrl = instructionVideoUrl;
        }
    }
}
