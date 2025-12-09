package capstone_1.Ecotrack_backend.model;

import java.time.LocalDateTime;
import java.util.HashSet;
import java.util.Set;

import jakarta.persistence.*;

@Entity
@Table(name = "users")
public class User {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "user_id")
    private Long id;

    @Column(nullable = false, unique = true, length = 100)
    private String username;

    @Column(nullable = false, length = 255)
    private String password;

    @Column(nullable = false, length = 100)
    private String email;

    @Column(name = "account_non_expired")
    private Boolean accountNonExpired = true;

    @Column(name = "is_enabled")
    private Boolean enabled = true;

    @Column(name = "account_non_locked")
    private Boolean accountNonLocked = true;

    @Column(name = "credentials_non_expired")
    private Boolean credentialsNonExpired = true;

    @Column(name = "verification_code")
    private String verificationCode;

    @Column(name = "is_verified")
    private boolean isVerified = false;

    @Column(name = "provider_id")
    private String providerId;

    @Column(name = "last_credentials_update")
    private LocalDateTime lastCredentialsUpdate; // Thời gian email/password bị thay đổi

    @ManyToMany(fetch = FetchType.EAGER)
    @JoinTable(
            name = "user_role",
            joinColumns = @JoinColumn(name = "user_id"),
            inverseJoinColumns = @JoinColumn(name = "role_id")
    )
    private Set<Role> roles = new HashSet<>();


    @OneToOne(mappedBy = "user", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private UserProfile userProfile;

    @OneToMany(mappedBy = "user")
    private Set<CampaignParticipant> campaignParticipants;

    // constructors, getters, setters
    public User() {
    }

    public User(Long id, String username, String password, String email, Boolean accountNonExpired, Boolean enabled, Boolean accountNonLocked, Boolean credentialsNonExpired, String verificationCode, boolean isVerified, String providerId, LocalDateTime lastCredentialsUpdate, Set<Role> roles, UserProfile userProfile, Set<CampaignParticipant> campaignParticipants) {
        this.id = id;
        this.username = username;
        this.password = password;
        this.email = email;
        this.accountNonExpired = accountNonExpired;
        this.enabled = enabled;
        this.accountNonLocked = accountNonLocked;
        this.credentialsNonExpired = credentialsNonExpired;
        this.verificationCode = verificationCode;
        this.isVerified = isVerified;
        this.providerId = providerId;
        this.lastCredentialsUpdate = lastCredentialsUpdate;
        this.roles = roles;
        this.userProfile = userProfile;
        this.campaignParticipants = campaignParticipants;
    }

    // getters and setters below...
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }

    public String getPassword() {
        return password;
    }

    public void setPassword(String password) {
        this.password = password;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public Boolean getAccountNonExpired() {
        return accountNonExpired;
    }

    public void setAccountNonExpired(Boolean accountNonExpired) {
        this.accountNonExpired = accountNonExpired;
    }

    public Boolean getEnabled() {
        return enabled;
    }

    public void setEnabled(Boolean enabled) {
        this.enabled = enabled;
    }

    public Boolean getAccountNonLocked() {
        return accountNonLocked;
    }

    public void setAccountNonLocked(Boolean accountNonLocked) {
        this.accountNonLocked = accountNonLocked;
    }

    public Boolean getCredentialsNonExpired() {
        return credentialsNonExpired;
    }

    public String getVerificationCode() {
        return verificationCode;
    }

    public void setVerificationCode(String verificationCode) {
        this.verificationCode = verificationCode;
    }

    public boolean isVerified() {
        return isVerified;
    }

    public void setVerified(boolean verified) {
        isVerified = verified;
    }

    public void setCredentialsNonExpired(Boolean credentialsNonExpired) {
        this.credentialsNonExpired = credentialsNonExpired;
    }

    public String getProviderId() {
        return providerId;
    }

    public void setProviderId(String providerId) {
        this.providerId = providerId;
    }

    public Set<Role> getRoles() {
        return roles;
    }

    public void setRoles(Set<Role> roles) {
        this.roles = roles;
    }

    public UserProfile getUserProfile() { return userProfile; }
    public void setUserProfile(UserProfile userProfile) {
        this.userProfile = userProfile;
        if (userProfile != null) {
            userProfile.setUser(this);
        }
    }

    public LocalDateTime getLastCredentialsUpdate() {
        return lastCredentialsUpdate;
    }

    public void setLastCredentialsUpdate(LocalDateTime lastCredentialsUpdate) {
        this.lastCredentialsUpdate = lastCredentialsUpdate;
    }

    public Set<CampaignParticipant> getCampaignParticipants() {
        return campaignParticipants;
    }

    public void setCampaignParticipants(Set<CampaignParticipant> campaignParticipants) {
        this.campaignParticipants = campaignParticipants;
    }
}