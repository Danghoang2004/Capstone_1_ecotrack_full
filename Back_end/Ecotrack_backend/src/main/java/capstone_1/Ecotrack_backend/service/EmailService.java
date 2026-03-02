package capstone_1.Ecotrack_backend.service;

public interface EmailService {
    public void sendMessage(String from, String to, String subject, String text);

    void sendOtpEmail(String to, String otp);
}
