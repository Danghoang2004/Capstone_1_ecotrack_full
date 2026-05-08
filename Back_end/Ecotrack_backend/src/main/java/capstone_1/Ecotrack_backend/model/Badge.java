package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "badges")
public class Badge {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "badge_id")
    private Long badgeId;

    @Column(name = "badge_name", nullable = false)
    private String badgeName;

    @Column(name = "description")
    private String description;

    @Column(name = "icon_url")
    private String iconUrl;

    @Column(name = "requirement", columnDefinition = "TEXT")
    private String requirement;

    @Column(name = "points_required", nullable = false, columnDefinition = "INT DEFAULT 0")
    private Integer pointsRequired = 0;

    public Badge() {
    }

    public Badge(Long badgeId, String badgeName, String description, String iconUrl, String requirement,
            Integer pointsRequired) {
        this.badgeId = badgeId;
        this.badgeName = badgeName;
        this.description = description;
        this.iconUrl = iconUrl;
        this.requirement = requirement;
        this.pointsRequired = pointsRequired;
    }

    public Long getBadgeId() {
        return badgeId;
    }

    public void setBadgeId(Long badgeId) {
        this.badgeId = badgeId;
    }

    public String getBadgeName() {
        return badgeName;
    }

    public void setBadgeName(String badgeName) {
        this.badgeName = badgeName;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getIconUrl() {
        return iconUrl;
    }

    public void setIconUrl(String iconUrl) {
        this.iconUrl = iconUrl;
    }

    public String getRequirement() {
        return requirement;
    }

    public void setRequirement(String requirement) {
        this.requirement = requirement;
    }

    public Integer getPointsRequired() {
        return pointsRequired;
    }

    public void setPointsRequired(Integer pointsRequired) {
        this.pointsRequired = pointsRequired;
    }
}