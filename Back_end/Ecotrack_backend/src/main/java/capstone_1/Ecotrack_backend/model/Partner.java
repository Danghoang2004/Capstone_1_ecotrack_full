package capstone_1.Ecotrack_backend.model;

import jakarta.persistence.*;

@Entity
@Table(name = "partners")
public class Partner {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "partner_id")
    private Long partnerId;

    @Column(name = "user_id", nullable = false, unique = true)
    private Long userId;

    @Column(name = "company_name", length = 200)
    private String companyName;

    @Column(name = "website", length = 200)
    private String website;

    @Column(name = "logo_url", length = 255)
    private String logoUrl;

    public Partner() {
    }

    public Partner(Long partnerId, Long userId, String companyName, String website, String logoUrl) {
        this.partnerId = partnerId;
        this.userId = userId;
        this.companyName = companyName;
        this.website = website;
        this.logoUrl = logoUrl;
    }

    public Long getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(Long partnerId) {
        this.partnerId = partnerId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getWebsite() {
        return website;
    }

    public void setWebsite(String website) {
        this.website = website;
    }

    public String getLogoUrl() {
        return logoUrl;
    }

    public void setLogoUrl(String logoUrl) {
        this.logoUrl = logoUrl;
    }
}