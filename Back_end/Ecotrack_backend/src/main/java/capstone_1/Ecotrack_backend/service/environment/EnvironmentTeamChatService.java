package capstone_1.Ecotrack_backend.service.environment;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.response.environment.EnvironmentTeamChatMessageResponse;
import capstone_1.Ecotrack_backend.exception.InvalidTaskStateException;
import capstone_1.Ecotrack_backend.exception.ResourceNotFoundException;
import capstone_1.Ecotrack_backend.model.EnvironmentTeam;
import capstone_1.Ecotrack_backend.model.EnvironmentTeamChatMessage;
import capstone_1.Ecotrack_backend.model.EnvironmentTeamChatReadState;
import capstone_1.Ecotrack_backend.model.EnvironmentTeamMember;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamChatMessageRepository;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamChatReadStateRepository;
import capstone_1.Ecotrack_backend.repository.EnvironmentTeamMemberRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class EnvironmentTeamChatService {

    private static final int DEFAULT_LIMIT = 80;
    private static final int MAX_LIMIT = 200;
    private static final long MAX_ATTACHMENT_SIZE_BYTES = 20L * 1024L * 1024L;

    private final EnvironmentTeamMemberRepository environmentTeamMemberRepository;
    private final EnvironmentTeamChatMessageRepository environmentTeamChatMessageRepository;
    private final EnvironmentTeamChatReadStateRepository environmentTeamChatReadStateRepository;
    private final UserRepository userRepository;
    private final CloudinaryService cloudinaryService;

    public EnvironmentTeamChatService(EnvironmentTeamMemberRepository environmentTeamMemberRepository,
            EnvironmentTeamChatMessageRepository environmentTeamChatMessageRepository,
            EnvironmentTeamChatReadStateRepository environmentTeamChatReadStateRepository,
            UserRepository userRepository,
            CloudinaryService cloudinaryService) {
        this.environmentTeamMemberRepository = environmentTeamMemberRepository;
        this.environmentTeamChatMessageRepository = environmentTeamChatMessageRepository;
        this.environmentTeamChatReadStateRepository = environmentTeamChatReadStateRepository;
        this.userRepository = userRepository;
        this.cloudinaryService = cloudinaryService;
    }

    @Transactional
    public EnvironmentTeamChatMessageResponse sendMessage(Long currentUserId, String rawMessage) {
        String message = rawMessage == null ? "" : rawMessage.trim();
        if (message.isEmpty()) {
            throw new InvalidTaskStateException("Nội dung tin nhắn không được để trống.");
        }

        EnvironmentTeam team = resolveMyActiveTeam(currentUserId);

        EnvironmentTeamChatMessage chatMessage = new EnvironmentTeamChatMessage();
        chatMessage.setTeam(team);
        chatMessage.setSenderUserId(currentUserId);
        chatMessage.setMessageText(message);
        chatMessage.setMessageType("TEXT");
        chatMessage.setSentAt(LocalDateTime.now());

        EnvironmentTeamChatMessage saved = environmentTeamChatMessageRepository.save(chatMessage);
        List<Long> activeMemberIds = loadActiveMemberIds(team.getTeamId());
        return toResponse(saved, currentUserId, Collections.emptyMap(), 1, activeMemberIds.size());
    }

    @Transactional
    public EnvironmentTeamChatMessageResponse sendAttachment(Long currentUserId, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new InvalidTaskStateException("Tệp đính kèm không hợp lệ.");
        }
        if (file.getSize() > MAX_ATTACHMENT_SIZE_BYTES) {
            throw new InvalidTaskStateException("Tệp đính kèm vượt quá giới hạn 20MB.");
        }

        EnvironmentTeam team = resolveMyActiveTeam(currentUserId);

        String uploadedUrl;
        try {
            Map<String, Object> uploadResult = cloudinaryService.uploadFile(file, "ecotrack/environment-chat");
            Object secureUrl = uploadResult.get("secure_url");
            if (secureUrl == null || secureUrl.toString().isBlank()) {
                throw new InvalidTaskStateException("Không thể tải tệp đính kèm lên máy chủ.");
            }
            uploadedUrl = secureUrl.toString();
        } catch (InvalidTaskStateException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new InvalidTaskStateException("Không thể tải tệp đính kèm lên máy chủ.");
        }

        String contentType = file.getContentType() == null ? "application/octet-stream" : file.getContentType();
        String fileName = file.getOriginalFilename() == null || file.getOriginalFilename().isBlank()
                ? "tep-dinh-kem"
                : file.getOriginalFilename();

        EnvironmentTeamChatMessage chatMessage = new EnvironmentTeamChatMessage();
        chatMessage.setTeam(team);
        chatMessage.setSenderUserId(currentUserId);
        chatMessage.setMessageText(fileName);
        chatMessage.setMessageType(contentType.startsWith("image/") ? "IMAGE" : "FILE");
        chatMessage.setAttachmentUrl(uploadedUrl);
        chatMessage.setAttachmentName(fileName);
        chatMessage.setAttachmentMimeType(contentType);
        chatMessage.setAttachmentSizeBytes(file.getSize());
        chatMessage.setSentAt(LocalDateTime.now());

        EnvironmentTeamChatMessage saved = environmentTeamChatMessageRepository.save(chatMessage);
        List<Long> activeMemberIds = loadActiveMemberIds(team.getTeamId());
        return toResponse(saved, currentUserId, Collections.emptyMap(), 1, activeMemberIds.size());
    }

    @Transactional(readOnly = true)
    public List<EnvironmentTeamChatMessageResponse> getMessages(Long currentUserId, Long afterMessageId,
            Integer limit) {
        EnvironmentTeam team = resolveMyActiveTeam(currentUserId);
        int finalLimit = sanitizeLimit(limit);

        List<EnvironmentTeamChatMessage> messages;
        if (afterMessageId != null && afterMessageId > 0) {
            messages = environmentTeamChatMessageRepository
                    .findByTeamTeamIdAndMessageIdGreaterThanOrderByMessageIdAsc(team.getTeamId(), afterMessageId,
                            PageRequest.of(0, finalLimit));
        } else {
            messages = environmentTeamChatMessageRepository
                    .findByTeamTeamIdOrderByMessageIdDesc(team.getTeamId(), PageRequest.of(0, finalLimit));
            Collections.reverse(messages);
        }

        // Skip read-state persistence in GET flow to support read-only DB connections.

        List<Long> activeMemberIds = loadActiveMemberIds(team.getTeamId());
        Map<Long, Long> memberReadMap = loadMemberReadProgress(team.getTeamId(), activeMemberIds);

        Map<Long, User> sendersById = loadSenders(messages);

        return messages.stream()
                .map(message -> toResponse(
                        message,
                        currentUserId,
                        sendersById,
                        countSeenBy(message.getMessageId(), memberReadMap),
                        activeMemberIds.size()))
                .toList();
    }

    private EnvironmentTeam resolveMyActiveTeam(Long currentUserId) {
        EnvironmentTeamMember membership = environmentTeamMemberRepository.findByUserIdAndIsActiveTrue(currentUserId)
                .stream()
                .findFirst()
                .orElseThrow(() -> new ResourceNotFoundException("Bạn chưa thuộc đội môi trường nào."));

        EnvironmentTeam team = membership.getTeam();
        if (team == null || !Boolean.TRUE.equals(team.getIsActive())) {
            throw new ResourceNotFoundException("Đội môi trường không tồn tại hoặc đã ngừng hoạt động.");
        }

        return team;
    }

    private int sanitizeLimit(Integer limit) {
        if (limit == null || limit <= 0) {
            return DEFAULT_LIMIT;
        }
        return Math.min(limit, MAX_LIMIT);
    }

    private void upsertReadState(EnvironmentTeam team, Long userId, Long latestReadMessageId) {
        if (team == null || team.getTeamId() == null || userId == null) {
            return;
        }

        try {
            EnvironmentTeamChatReadState readState = environmentTeamChatReadStateRepository
                    .findByTeamTeamIdAndUserId(team.getTeamId(), userId)
                    .orElseGet(EnvironmentTeamChatReadState::new);

            if (readState.getReadId() == null) {
                readState.setTeam(team);
                readState.setUserId(userId);
                readState.setLastReadMessageId(Math.max(0L, latestReadMessageId));
                readState.setLastSeenAt(LocalDateTime.now());
                environmentTeamChatReadStateRepository.save(readState);
                return;
            }

            long currentValue = readState.getLastReadMessageId() == null ? 0L : readState.getLastReadMessageId();
            if (latestReadMessageId > currentValue) {
                readState.setLastReadMessageId(latestReadMessageId);
            }
            readState.setLastSeenAt(LocalDateTime.now());
            environmentTeamChatReadStateRepository.save(readState);
        } catch (DataIntegrityViolationException ex) {
            EnvironmentTeamChatReadState existing = environmentTeamChatReadStateRepository
                    .findByTeamTeamIdAndUserId(team.getTeamId(), userId)
                    .orElse(null);
            if (existing == null) {
                return;
            }

            long currentValue = existing.getLastReadMessageId() == null ? 0L : existing.getLastReadMessageId();
            if (latestReadMessageId > currentValue) {
                existing.setLastReadMessageId(latestReadMessageId);
            }
            existing.setLastSeenAt(LocalDateTime.now());
            environmentTeamChatReadStateRepository.save(existing);
        }
    }

    private List<Long> loadActiveMemberIds(Long teamId) {
        return environmentTeamMemberRepository.findByTeamTeamIdAndIsActiveTrue(teamId).stream()
                .map(EnvironmentTeamMember::getUserId)
                .toList();
    }

    private Map<Long, Long> loadMemberReadProgress(Long teamId, List<Long> memberIds) {
        if (memberIds.isEmpty()) {
            return Collections.emptyMap();
        }

        Map<Long, Long> readProgress = new HashMap<>();
        for (EnvironmentTeamChatReadState state : environmentTeamChatReadStateRepository
                .findByTeamTeamIdAndUserIdIn(teamId, memberIds)) {
            readProgress.put(state.getUserId(),
                    state.getLastReadMessageId() == null ? 0L : state.getLastReadMessageId());
        }
        return readProgress;
    }

    private int countSeenBy(Long messageId, Map<Long, Long> memberReadMap) {
        int count = 0;
        for (Long lastReadMessageId : memberReadMap.values()) {
            if (lastReadMessageId != null && lastReadMessageId >= messageId) {
                count++;
            }
        }
        return count;
    }

    private Map<Long, User> loadSenders(List<EnvironmentTeamChatMessage> messages) {
        Set<Long> senderIds = messages.stream()
                .map(EnvironmentTeamChatMessage::getSenderUserId)
                .collect(Collectors.toSet());

        if (senderIds.isEmpty()) {
            return Collections.emptyMap();
        }

        return userRepository.findAllById(senderIds).stream()
                .collect(Collectors.toMap(User::getId, user -> user));
    }

    private EnvironmentTeamChatMessageResponse toResponse(EnvironmentTeamChatMessage message,
            Long currentUserId,
            Map<Long, User> sendersById,
            Integer seenByCount,
            Integer totalMemberCount) {
        User sender = sendersById.get(message.getSenderUserId());
        if (sender == null) {
            sender = userRepository.findById(message.getSenderUserId()).orElse(null);
        }

        String fullName = "Thành viên";
        String username = "";
        String avatar = null;

        if (sender != null) {
            username = sender.getUsername() == null ? "" : sender.getUsername();
            fullName = sender.getUserProfile() != null && sender.getUserProfile().getFullName() != null
                    ? sender.getUserProfile().getFullName()
                    : username;
            avatar = sender.getUserProfile() == null ? null : sender.getUserProfile().getAvatarUrl();
        }

        EnvironmentTeamChatMessageResponse response = new EnvironmentTeamChatMessageResponse();
        response.setMessageId(message.getMessageId());
        response.setTeamId(message.getTeam().getTeamId());
        response.setSenderUserId(message.getSenderUserId());
        response.setSenderFullName(fullName);
        response.setSenderUsername(username);
        response.setSenderAvatarUrl(avatar);
        response.setMessage(message.getMessageText());
        response.setMessageType(message.getMessageType() == null ? "TEXT" : message.getMessageType());
        response.setAttachmentUrl(message.getAttachmentUrl());
        response.setAttachmentName(message.getAttachmentName());
        response.setAttachmentMimeType(message.getAttachmentMimeType());
        response.setAttachmentSizeBytes(message.getAttachmentSizeBytes());
        response.setSentAt(message.getSentAt());
        response.setMine(message.getSenderUserId().equals(currentUserId));
        response.setSeenByCount(seenByCount == null ? 0 : seenByCount);
        response.setTotalMemberCount(totalMemberCount == null ? 0 : totalMemberCount);
        response.setSeenByAll(totalMemberCount != null && totalMemberCount > 0 && seenByCount != null
                && seenByCount >= totalMemberCount);
        return response;
    }
}