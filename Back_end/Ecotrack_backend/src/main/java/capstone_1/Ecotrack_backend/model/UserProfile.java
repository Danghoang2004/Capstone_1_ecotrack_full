package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;

@Entity
@Table(name = "user_profiles")
public class UserProfile {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "profile_id")
    private Long profileId;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(name = "full_name", length = 100)
    private String fullName;

    @Column(name = "avatar_url", length = 255)
    private String avatarUrl = "default_avatar.png";

    public enum Gender { M, F, O }

    @Enumerated(EnumType.STRING)
    @Column(name = "gender")
    private Gender gender;

    @Column(name = "birth_date")
    private LocalDate birthDate;

    @Column(name = "location", length = 150)
    private String location;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "level_id")
    private Level level;

    @Column(name = "quiz_streak")
    private Integer quizStreak = 0;

    @Column(name = "last_quiz_date")
    private LocalDate lastQuizDate;

    public UserProfile() {
    }

    public UserProfile(Long profileId, User user, String fullName, String avatarUrl, Gender gender, LocalDate birthDate, String location, Level level, Integer quizStreak, LocalDate lastQuizDate) {
        this.profileId = profileId;
        this.user = user;
        this.fullName = fullName;
        this.avatarUrl = avatarUrl;
        this.gender = gender;
        this.birthDate = birthDate;
        this.location = location;
        this.level = level;
        this.quizStreak = quizStreak;
        this.lastQuizDate = lastQuizDate;
    }

    public Long getProfileId() {
        return profileId;
    }

    public void setProfileId(Long profileId) {
        this.profileId = profileId;
    }

    public User getUser() {
        return user;
    }

    public void setUser(User user) {
        this.user = user;
    }

    public String getFullName() {
        return fullName;
    }

    public void setFullName(String fullName) {
        this.fullName = fullName;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public Gender getGender() {
        return gender;
    }

    public void setGender(Gender gender) {
        this.gender = gender;
    }

    public LocalDate getBirthDate() {
        return birthDate;
    }

    public void setBirthDate(LocalDate birthDate) {
        this.birthDate = birthDate;
    }

    public String getLocation() {
        return location;
    }

    public void setLocation(String location) {
        this.location = location;
    }

    public Level getLevel() {
        return level;
    }

    public void setLevel(Level level) {
        this.level = level;
    }

    public Integer getQuizStreak() {
        return quizStreak;
    }

    public void setQuizStreak(Integer quizStreak) {
        this.quizStreak = quizStreak;
    }

    public LocalDate getLastQuizDate() {
        return lastQuizDate;
    }

    public void setLastQuizDate(LocalDate lastQuizDate) {
        this.lastQuizDate = lastQuizDate;
    }
}
