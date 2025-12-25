package capstone_1.Ecotrack_backend.dto.response;

public class PartnerSettingsResponse {

    private Long partnerId;
    private String companyName;
    private String email;
    private String phoneNumber;
    private String website;
    private String logoUrl;

    public PartnerSettingsResponse() {}

    public PartnerSettingsResponse(
            Long partnerId,
            String companyName,
            String email,
            String phoneNumber,
            String website,
            String logoUrl
    ) {
        this.partnerId = partnerId;
        this.companyName = companyName;
        this.email = email;
        this.phoneNumber = phoneNumber;
        this.website = website;
        this.logoUrl = logoUrl;
    }

    public Long getPartnerId() {
        return partnerId;
    }

    public void setPartnerId(Long partnerId) {
        this.partnerId = partnerId;
    }

    public String getCompanyName() {
        return companyName;
    }

    public void setCompanyName(String companyName) {
        this.companyName = companyName;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPhoneNumber() {
        return phoneNumber;
    }

    public void setPhoneNumber(String phoneNumber) {
        this.phoneNumber = phoneNumber;
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
