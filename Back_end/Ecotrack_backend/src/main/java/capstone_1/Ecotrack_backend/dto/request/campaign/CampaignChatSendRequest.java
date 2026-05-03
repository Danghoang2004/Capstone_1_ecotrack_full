package capstone_1.Ecotrack_backend.dto.request.campaign;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class CampaignChatSendRequest {

    @NotBlank(message = "Nội dung tin nhắn không được để trống.")
    private String message;
}
