package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "user_points")
public class UserPoints {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @Column(name = "points")
    private Integer points = 0;

    @OneToOne
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    public UserPoints() {
    }

    public UserPoints(Long userId, Integer points, User user) {
        this.userId = userId;
        this.points = points;
        this.user = user;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Integer getPoints() {
        return points;
    }

    public void setPoints(Integer points) {
        this.points = points;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }
}

