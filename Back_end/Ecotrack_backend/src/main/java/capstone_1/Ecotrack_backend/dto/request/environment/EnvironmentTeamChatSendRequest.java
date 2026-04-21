package capstone_1.Ecotrack_backend.dto.request.environment;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class EnvironmentTeamChatSendRequest {

    @NotBlank(message = "Nội dung tin nhắn không được để trống.")
    @Size(max = 1500, message = "Tin nhắn tối đa 1500 ký tự.")
    private String message;

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}