package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "recycle_suggestions")
public class RecycleGuide {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "suggestion_id")
    private Long guideId;

    @Column(name = "waste_type_key", nullable = false)
    private String wasteTypeKey;

    @Column(name = "waste_type_label", nullable = false)
    private String wasteTypeLabel;

    @Column(name = "title", nullable = false)
    private String name;

    @Column(name = "short_description", columnDefinition = "TEXT")
    private String description;

    @Column(name = "recycle_image_url")
    private String imageUrl;

    @Column(name = "difficulty_level")
    private String difficultyLevel;

    @Column(name = "estimated_time_minutes")
    private Integer estimatedTimeMinutes;

    @Column(name = "materials_needed", columnDefinition = "LONGTEXT")
    private String materialsNeeded;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public RecycleGuide() {}

    public Long getGuideId() { return guideId; }
    public void setGuideId(Long guideId) { this.guideId = guideId; }

    public String getWasteTypeKey() { return wasteTypeKey; }
    public void setWasteTypeKey(String wasteTypeKey) { this.wasteTypeKey = wasteTypeKey; }

    public String getWasteTypeLabel() { return wasteTypeLabel; }
    public void setWasteTypeLabel(String wasteTypeLabel) { this.wasteTypeLabel = wasteTypeLabel; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getDifficultyLevel() { return difficultyLevel; }
    public void setDifficultyLevel(String difficultyLevel) { this.difficultyLevel = difficultyLevel; }

    public Integer getEstimatedTimeMinutes() { return estimatedTimeMinutes; }
    public void setEstimatedTimeMinutes(Integer estimatedTimeMinutes) { this.estimatedTimeMinutes = estimatedTimeMinutes; }

    public String getMaterialsNeeded() { return materialsNeeded; }
    public void setMaterialsNeeded(String materialsNeeded) { this.materialsNeeded = materialsNeeded; }

    public Boolean getIsActive() { return isActive; }
    public void setIsActive(Boolean isActive) { this.isActive = isActive; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }

    // Helper: extract steps count from title pattern (not used in existing DB, kept for compatibility)
    public String getSteps() { return ""; }
    public void setSteps(String steps) { }
}
