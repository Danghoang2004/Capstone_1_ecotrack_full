package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.model.WasteReport;
import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;

@Service
public class AdminRealtimeSseService {

    private static final long SSE_TIMEOUT_MS = 0L;
    private final List<SseEmitter> emitters = new CopyOnWriteArrayList<>();
    private final ScheduledExecutorService heartbeatExecutor = Executors.newSingleThreadScheduledExecutor();

    @PostConstruct
    public void startHeartbeat() {
        heartbeatExecutor.scheduleAtFixedRate(() -> broadcast("HEARTBEAT", Map.of(
                "eventType", "HEARTBEAT",
                "time", LocalDateTime.now().toString()
        )), 20, 20, TimeUnit.SECONDS);
    }

    @PreDestroy
    public void shutdown() {
        heartbeatExecutor.shutdownNow();
        emitters.forEach(SseEmitter::complete);
        emitters.clear();
    }

    public SseEmitter subscribe() {
        SseEmitter emitter = new SseEmitter(SSE_TIMEOUT_MS);
        emitters.add(emitter);

        emitter.onCompletion(() -> emitters.remove(emitter));
        emitter.onTimeout(() -> emitters.remove(emitter));
        emitter.onError((ex) -> emitters.remove(emitter));

        sendSingleEvent(emitter, "CONNECTED", Map.of(
                "eventType", "CONNECTED",
                "time", LocalDateTime.now().toString()
        ));

        return emitter;
    }

    public void publishReportCreated(WasteReport report) {
        broadcast("REPORT_CREATED", Map.of(
                "eventType", "REPORT_CREATED",
                "reportId", report.getReportId(),
                "status", report.getStatus().name(),
                "title", report.getTitle(),
                "time", LocalDateTime.now().toString()
        ));
    }

    public void publishReportStatusUpdated(WasteReport report) {
        broadcast("REPORT_STATUS_UPDATED", Map.of(
                "eventType", "REPORT_STATUS_UPDATED",
                "reportId", report.getReportId(),
                "status", report.getStatus().name(),
                "title", report.getTitle(),
                "time", LocalDateTime.now().toString()
        ));
    }

    public void publishCampaignParticipantUpdated(Long campaignId, int participants, int maxParticipants) {
        broadcast("CAMPAIGN_PARTICIPANT_UPDATED", Map.of(
                "eventType", "CAMPAIGN_PARTICIPANT_UPDATED",
                "campaignId", campaignId,
                "participants", participants,
                "maxParticipants", maxParticipants,
                "time", LocalDateTime.now().toString()
        ));
    }

    private void broadcast(String eventName, Object payload) {
        for (SseEmitter emitter : emitters) {
            sendSingleEvent(emitter, eventName, payload);
        }
    }

    private void sendSingleEvent(SseEmitter emitter, String eventName, Object payload) {
        try {
            emitter.send(SseEmitter.event().name(eventName).data(payload));
        } catch (IOException | IllegalStateException ex) {
            emitters.remove(emitter);
            emitter.complete();
        }
    }
}