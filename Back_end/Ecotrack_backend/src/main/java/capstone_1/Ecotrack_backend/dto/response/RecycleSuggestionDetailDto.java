package capstone_1.Ecotrack_backend.dto.response;

import java.util.ArrayList;
import java.util.List;

public class RecycleSuggestionDetailDto {

    private Long suggestionId;
    private String wasteTypeKey;
    private String wasteTypeLabel;
    private String title;
    private String shortDescription;
    private String recycleImageUrl;
    private String difficultyLevel;
    private Integer estimatedTimeMinutes;
    private String materialsNeeded;
    private List<RecycleSuggestionStepDto> steps = new ArrayList<>();

    public Long getSuggestionId() {
        return suggestionId;
    }

    public void setSuggestionId(Long suggestionId) {
        this.suggestionId = suggestionId;
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

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getShortDescription() {
        return shortDescription;
    }

    public void setShortDescription(String shortDescription) {
        this.shortDescription = shortDescription;
    }

    public String getRecycleImageUrl() {
        return recycleImageUrl;
    }

    public void setRecycleImageUrl(String recycleImageUrl) {
        this.recycleImageUrl = recycleImageUrl;
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

    public List<RecycleSuggestionStepDto> getSteps() {
        return steps;
    }

    public void setSteps(List<RecycleSuggestionStepDto> steps) {
        this.steps = steps;
    }
}
