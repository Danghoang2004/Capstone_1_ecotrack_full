package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "environment_team_members")
public class EnvironmentTeamMember {

    public enum TeamRole {
        LEAD,
        MEMBER
    }

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "team_member_id")
    private Long teamMemberId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "team_id", nullable = false)
    private EnvironmentTeam team;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(name = "role", nullable = false)
    private TeamRole role = TeamRole.MEMBER;

    @Column(name = "is_active", nullable = false)
    private Boolean isActive = true;

    @Column(name = "joined_at", nullable = false)
    private LocalDateTime joinedAt = LocalDateTime.now();

    @Column(name = "removed_at")
    private LocalDateTime removedAt;

    public Long getTeamMemberId() {
        return teamMemberId;
    }

    public void setTeamMemberId(Long teamMemberId) {
        this.teamMemberId = teamMemberId;
    }

    public EnvironmentTeam getTeam() {
        return team;
    }

    public void setTeam(EnvironmentTeam team) {
        this.team = team;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public TeamRole getRole() {
        return role;
    }

    public void setRole(TeamRole role) {
        this.role = role;
    }

    public Boolean getIsActive() {
        return isActive;
    }

    public void setIsActive(Boolean active) {
        isActive = active;
    }

    public LocalDateTime getJoinedAt() {
        return joinedAt;
    }

    public void setJoinedAt(LocalDateTime joinedAt) {
        this.joinedAt = joinedAt;
    }

    public LocalDateTime getRemovedAt() {
        return removedAt;
    }

    public void setRemovedAt(LocalDateTime removedAt) {
        this.removedAt = removedAt;
    }
}
