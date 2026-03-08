package capstone_1.Ecotrack_backend.dto.request;

public class ResetPasswordRequestWithOtp {

    private String email;
    private String newPassword;
    private String confirmPassword;

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getNewPassword() {
        return newPassword;
    }

    public void setNewPassword(String newPassword) {
        this.newPassword = newPassword;
    }

    public String getConfirmPassword() {
        return confirmPassword;
    }

    public String confirmPassword() {
        return confirmPassword;
    }

}