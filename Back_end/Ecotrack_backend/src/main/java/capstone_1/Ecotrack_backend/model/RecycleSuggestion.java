package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.CascadeType;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.OneToMany;
import jakarta.persistence.OrderBy;
import jakarta.persistence.Table;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "recycle_suggestions")
public class RecycleSuggestion {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "suggestion_id")
    private Long suggestionId;

    @Column(name = "waste_type_key", nullable = false, length = 100)
    private String wasteTypeKey;

    @Column(name = "waste_type_label", nullable = false, length = 150)
    private String wasteTypeLabel;

    @Column(name = "title", nullable = false, length = 200)
    private String title;

    @Column(name = "short_description", length = 500)
    private String shortDescription;

    @Column(name = "recycle_image_url", nullable = false, length = 500)
    private String recycleImageUrl;

    @Column(name = "difficulty_level", length = 50)
    private String difficultyLevel;

    @Column(name = "estimated_time_minutes")
    private Integer estimatedTimeMinutes;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();
    @Column(name = "materials_needed", nullable = false, columnDefinition = "LONGTEXT")
    private String materialsNeeded;

    @OneToMany(mappedBy = "suggestion", cascade = CascadeType.ALL, fetch = FetchType.LAZY, orphanRemoval = true)
    @OrderBy("stepOrder ASC")
    private List<RecycleSuggestionStep> steps = new ArrayList<>();

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

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public List<RecycleSuggestionStep> getSteps() {
        return steps;
    }

    public void setSteps(List<RecycleSuggestionStep> steps) {
        this.steps = steps;
    }

    public String getMaterialsNeeded() {
        return materialsNeeded;
    }

    public void setMaterialsNeeded(String materialsNeeded) {
        this.materialsNeeded = materialsNeeded;
    }
}
