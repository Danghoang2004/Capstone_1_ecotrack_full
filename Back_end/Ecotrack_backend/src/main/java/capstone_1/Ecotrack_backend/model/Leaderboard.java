package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "leaderboard")
public class Leaderboard {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "leaderboard_id")
    private Long leaderboardId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "rank_position")
    private Integer rankPosition;

    @Column(name = "score")
    private Integer score;

    @Column(name = "snapshot_date")
    private LocalDate snapshotDate;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt = LocalDateTime.now();

    // getters / setters
    public Long getLeaderboardId() { return leaderboardId; }
    public void setLeaderboardId(Long leaderboardId) { this.leaderboardId = leaderboardId; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public Integer getRankPosition() { return rankPosition; }
    public void setRankPosition(Integer rankPosition) { this.rankPosition = rankPosition; }

    public Integer getScore() { return score; }
    public void setScore(Integer score) { this.score = score; }

    public LocalDate getSnapshotDate() { return snapshotDate; }
    public void setSnapshotDate(LocalDate snapshotDate) { this.snapshotDate = snapshotDate; }

    public LocalDateTime getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(LocalDateTime updatedAt) { this.updatedAt = updatedAt; }
}
