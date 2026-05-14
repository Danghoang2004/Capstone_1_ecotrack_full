package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.request.campaign.CampaignChatSendRequest;
import capstone_1.Ecotrack_backend.dto.response.campaign.CampaignChatMessageResponse;
import capstone_1.Ecotrack_backend.service.CampaignChatService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/campaigns/{campaignId}/chat")
public class CampaignChatController {

    private final CampaignChatService campaignChatService;

    public CampaignChatController(CampaignChatService campaignChatService) {
        this.campaignChatService = campaignChatService;
    }

    @GetMapping("/messages")
    public List<CampaignChatMessageResponse> getMessages(
            @PathVariable Long campaignId,
            @RequestParam(required = false) Long afterMessageId,
            @RequestParam(required = false) Integer limit,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return campaignChatService.getMessages(campaignId, userId, afterMessageId, limit);
    }

    @PostMapping("/messages")
    public CampaignChatMessageResponse sendMessage(
            @PathVariable Long campaignId,
            @Valid @RequestBody CampaignChatSendRequest body,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return campaignChatService.sendMessage(campaignId, userId, body.getMessage());
    }

    @PostMapping(value = "/messages/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public CampaignChatMessageResponse sendAttachment(
            @PathVariable Long campaignId,
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return campaignChatService.sendAttachment(campaignId, userId, file);
    }
}
