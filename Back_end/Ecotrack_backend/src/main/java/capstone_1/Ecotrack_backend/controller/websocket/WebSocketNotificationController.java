package capstone_1.Ecotrack_backend.controller.websocket;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.SendTo;
import org.springframework.messaging.simp.SimpMessageHeaderAccessor;
import org.springframework.messaging.simp.annotation.SubscribeMapping;
import org.springframework.stereotype.Controller;
import org.springframework.web.socket.messaging.SessionConnectEvent;

@Slf4j
@Controller
@RequiredArgsConstructor
public class WebSocketNotificationController {

    @SubscribeMapping("/notifications")
    public String handleSubscribe(SimpMessageHeaderAccessor headerAccessor) {
        String userId = headerAccessor.getUser() != null ? headerAccessor.getUser().getName() : "anonymous";
        log.info("User {} subscribed to notifications", userId);
        return "Connected to notifications endpoint";
    }

    @MessageMapping("/notifications/connect")
    @SendTo("/topic/notifications")
    public String handleConnect(SimpMessageHeaderAccessor headerAccessor) {
        String userId = headerAccessor.getUser() != null ? headerAccessor.getUser().getName() : "anonymous";
        log.info("User {} connected to WebSocket", userId);
        return "User " + userId + " connected";
    }

    @MessageMapping("/notifications/ping")
    public void handlePing(SimpMessageHeaderAccessor headerAccessor) {
        String userId = headerAccessor.getUser() != null ? headerAccessor.getUser().getName() : "anonymous";
        log.debug("Ping from user {}", userId);
    }
}
