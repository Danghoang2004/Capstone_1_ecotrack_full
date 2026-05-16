package capstone_1.Ecotrack_backend.dto.request;

import java.util.ArrayList;
import java.util.List;

public class AdminRecycleGuideUpsertRequest {
    private String wasteTypeKey;
    private String wasteTypeLabel;
    private String name;
    private String description;
    private String imageUrl;
    private String difficultyLevel;
    private Integer estimatedTimeMinutes;
    private String materialsNeeded;
    private Boolean isActive;
    private List<AdminRecycleStepUpsertRequest> steps = new ArrayList<>();

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

    public List<AdminRecycleStepUpsertRequest> getSteps() {
        return steps;
    }

    public void setSteps(List<AdminRecycleStepUpsertRequest> steps) {
        this.steps = steps;
    }
}
