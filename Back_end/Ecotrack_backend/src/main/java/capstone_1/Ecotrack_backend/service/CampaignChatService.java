package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.cloudinaryconfig.CloudinaryService;
import capstone_1.Ecotrack_backend.dto.response.campaign.CampaignChatMessageResponse;
import capstone_1.Ecotrack_backend.exception.InvalidTaskStateException;
import capstone_1.Ecotrack_backend.exception.ResourceNotFoundException;
import capstone_1.Ecotrack_backend.model.Campaign;
import capstone_1.Ecotrack_backend.model.CampaignChatMessage;
import capstone_1.Ecotrack_backend.model.CampaignParticipant;
import capstone_1.Ecotrack_backend.model.User;
import capstone_1.Ecotrack_backend.repository.CampaignChatMessageRepository;
import capstone_1.Ecotrack_backend.repository.CampaignParticipantRepository;
import capstone_1.Ecotrack_backend.repository.CampaignRepository;
import capstone_1.Ecotrack_backend.repository.UserRepository;
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
public class CampaignChatService {

	private static final int DEFAULT_LIMIT = 80;
	private static final int MAX_LIMIT = 200;
	private static final long MAX_ATTACHMENT_SIZE_BYTES = 20L * 1024L * 1024L;

	private final CampaignRepository campaignRepository;
	private final CampaignParticipantRepository participantRepository;
	private final CampaignChatMessageRepository chatMessageRepository;
	private final UserRepository userRepository;
	private final CloudinaryService cloudinaryService;

	public CampaignChatService(CampaignRepository campaignRepository,
			CampaignParticipantRepository participantRepository,
			CampaignChatMessageRepository chatMessageRepository,
			UserRepository userRepository,
			CloudinaryService cloudinaryService) {
		this.campaignRepository = campaignRepository;
		this.participantRepository = participantRepository;
		this.chatMessageRepository = chatMessageRepository;
		this.userRepository = userRepository;
		this.cloudinaryService = cloudinaryService;
	}

	@Transactional(readOnly = true)
	public List<CampaignChatMessageResponse> getMessages(Long campaignId, Long currentUserId, Long afterMessageId,
			Integer limit) {
		Campaign campaign = resolveJoinedCampaign(campaignId, currentUserId);
		int finalLimit = sanitizeLimit(limit);

		List<CampaignChatMessage> messages;
		if (afterMessageId != null && afterMessageId > 0) {
			messages = chatMessageRepository
					.findByCampaignCampaignIdAndIsDeletedFalseAndMessageIdGreaterThanOrderByMessageIdAsc(
							campaign.getCampaignId(), afterMessageId, PageRequest.of(0, finalLimit));
		} else {
			messages = chatMessageRepository
					.findByCampaignCampaignIdAndIsDeletedFalseOrderByMessageIdDesc(campaign.getCampaignId(),
							PageRequest.of(0, finalLimit));
			Collections.reverse(messages);
		}

		Map<Long, User> sendersById = loadSenders(messages);
		return messages.stream()
				.map(message -> toResponse(message, currentUserId, sendersById))
				.toList();
	}

	@Transactional
	public CampaignChatMessageResponse sendMessage(Long campaignId, Long currentUserId, String rawMessage) {
		String message = rawMessage == null ? "" : rawMessage.trim();
		if (message.isEmpty()) {
			throw new InvalidTaskStateException("Nội dung tin nhắn không được để trống.");
		}

		Campaign campaign = resolveJoinedCampaign(campaignId, currentUserId);

		CampaignChatMessage chatMessage = new CampaignChatMessage();
		chatMessage.setCampaign(campaign);
		chatMessage.setSenderUserId(currentUserId);
		chatMessage.setMessageText(message);
		chatMessage.setAttachmentType(null);
		chatMessage.setAttachmentUrl(null);
		chatMessage.setIsDeleted(false);

		CampaignChatMessage saved = chatMessageRepository.save(chatMessage);
		return toResponse(saved, currentUserId, Collections.emptyMap());
	}

	@Transactional
	public CampaignChatMessageResponse sendAttachment(Long campaignId, Long currentUserId, MultipartFile file) {
		if (file == null || file.isEmpty()) {
			throw new InvalidTaskStateException("Tệp đính kèm không hợp lệ.");
		}
		if (file.getSize() > MAX_ATTACHMENT_SIZE_BYTES) {
			throw new InvalidTaskStateException("Tệp đính kèm vượt quá giới hạn 20MB.");
		}

		Campaign campaign = resolveJoinedCampaign(campaignId, currentUserId);

		String uploadedUrl;
		try {
			Map<String, Object> uploadResult = cloudinaryService.uploadFile(file, "ecotrack/campaign-chat");
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

		CampaignChatMessage chatMessage = new CampaignChatMessage();
		chatMessage.setCampaign(campaign);
		chatMessage.setSenderUserId(currentUserId);
		chatMessage.setMessageText(fileName);
		chatMessage.setAttachmentUrl(uploadedUrl);
		chatMessage.setAttachmentType(contentType);
		chatMessage.setIsDeleted(false);

		CampaignChatMessage saved = chatMessageRepository.save(chatMessage);
		return toResponse(saved, currentUserId, Collections.emptyMap());
	}

	private Campaign resolveJoinedCampaign(Long campaignId, Long currentUserId) {
		if (campaignId == null) {
			throw new ResourceNotFoundException("Không tìm thấy chiến dịch.");
		}
		if (currentUserId == null) {
			throw new ResourceNotFoundException("Vui lòng đăng nhập để xem phòng chat.");
		}

		Campaign campaign = campaignRepository.findById(campaignId)
				.orElseThrow(() -> new ResourceNotFoundException("Chiến dịch không tồn tại."));

		boolean joined = participantRepository.existsById_CampaignIdAndId_UserId(campaignId, currentUserId);
		if (!joined) {
			throw new ResourceNotFoundException("Bạn chưa tham gia chiến dịch này.");
		}

		return campaign;
	}

	private int sanitizeLimit(Integer limit) {
		if (limit == null || limit <= 0) {
			return DEFAULT_LIMIT;
		}
		return Math.min(limit, MAX_LIMIT);
	}

	private Map<Long, User> loadSenders(List<CampaignChatMessage> messages) {
		Set<Long> senderIds = messages.stream()
				.map(CampaignChatMessage::getSenderUserId)
				.collect(Collectors.toSet());

		if (senderIds.isEmpty()) {
			return Collections.emptyMap();
		}

		return userRepository.findAllById(senderIds).stream()
				.collect(Collectors.toMap(User::getId, user -> user));
	}

	private CampaignChatMessageResponse toResponse(CampaignChatMessage message,
			Long currentUserId,
			Map<Long, User> sendersById) {
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

		CampaignChatMessageResponse response = new CampaignChatMessageResponse();
		response.setMessageId(message.getMessageId());
		response.setCampaignId(message.getCampaign().getCampaignId());
		response.setSenderUserId(message.getSenderUserId());
		response.setSenderFullName(fullName);
		response.setSenderUsername(username);
		response.setSenderAvatarUrl(avatar);
		response.setMessage(message.getMessageText());
		response.setAttachmentUrl(message.getAttachmentUrl());
		response.setAttachmentType(message.getAttachmentType());
		response.setCreatedAt(message.getCreatedAt());
		response.setUpdatedAt(message.getUpdatedAt());
		response.setMine(message.getSenderUserId().equals(currentUserId));
		return response;
	}
}
