package capstone_1.Ecotrack_backend.controller.environment;

import capstone_1.Ecotrack_backend.dto.request.environment.EnvironmentTeamChatSendRequest;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamChatMessageResponse;
import capstone_1.Ecotrack_backend.service.environment.EnvironmentTeamChatService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@RestController
@RequestMapping("/api/environment/team-chat")
@PreAuthorize("hasAuthority('ROLE_ENVIRONMENT')")
public class EnvironmentTeamChatController {

    private final EnvironmentTeamChatService environmentTeamChatService;

    public EnvironmentTeamChatController(EnvironmentTeamChatService environmentTeamChatService) {
        this.environmentTeamChatService = environmentTeamChatService;
    }

    @GetMapping("/messages")
    public List<EnvironmentTeamChatMessageResponse> getMessages(
            @RequestParam(required = false) Long afterMessageId,
            @RequestParam(required = false) Integer limit,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentTeamChatService.getMessages(userId, afterMessageId, limit);
    }

    @PostMapping("/messages")
    public EnvironmentTeamChatMessageResponse sendMessage(
            @Valid @RequestBody EnvironmentTeamChatSendRequest body,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentTeamChatService.sendMessage(userId, body.getMessage());
    }

    @PostMapping(value = "/messages/attachments", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    public EnvironmentTeamChatMessageResponse sendAttachment(
            @RequestParam("file") MultipartFile file,
            HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return environmentTeamChatService.sendAttachment(userId, file);
    }
}