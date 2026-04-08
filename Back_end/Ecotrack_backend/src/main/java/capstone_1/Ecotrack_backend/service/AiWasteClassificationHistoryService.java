package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.AiWasteClassificationResultDto;
import capstone_1.Ecotrack_backend.dto.response.ClassificationHistoryDetailDto;
import capstone_1.Ecotrack_backend.dto.response.ClassificationHistoryListItemDto;
import capstone_1.Ecotrack_backend.model.AiWasteClassificationHistory;
import capstone_1.Ecotrack_backend.repository.AiWasteClassificationHistoryRepository;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class AiWasteClassificationHistoryService {

    private final AiWasteClassificationHistoryRepository historyRepository;
    private final ObjectMapper objectMapper;

    public AiWasteClassificationHistoryService(
            AiWasteClassificationHistoryRepository historyRepository,
            ObjectMapper objectMapper) {
        this.historyRepository = historyRepository;
        this.objectMapper = objectMapper;
    }

    @Transactional
    public void saveResult(Long userId, String originalImageUrl, AiWasteClassificationResultDto result) {
        AiWasteClassificationHistory history = new AiWasteClassificationHistory();
        history.setUserId(userId);
        history.setTrashDetected(result.isTrashDetected());
        history.setOverallConfidence(result.getOverallConfidence());
        history.setTotalObjectsDetected(result.getTotalObjectsDetected());
        history.setWasteTypesJson(toJson(result.getWasteTypes()));
        history.setDetectionsJson(toJson(result.getDetections()));
        history.setRawResultJson(toJson(result));
        history.setOriginalImageUrl(originalImageUrl);
        history.setCreatedAt(LocalDateTime.now());

        historyRepository.save(history);
    }

    @Transactional(readOnly = true)
    public List<ClassificationHistoryListItemDto> getClassificationHistory(Long userId) {
        if (userId == null) {
            throw new IllegalArgumentException("User ID không được để trống.");
        }
        List<AiWasteClassificationHistory> histories = historyRepository.findByUserIdOrderByCreatedAtDesc(userId);
        List<ClassificationHistoryListItemDto> results = new ArrayList<>();
        for (AiWasteClassificationHistory history : histories) {
            results.add(toListItemDto(history));
        }
        return results;
    }

    @Transactional(readOnly = true)
    public ClassificationHistoryDetailDto getHistoryDetail(Long historyId) {
        if (historyId == null) {
            throw new IllegalArgumentException("History ID không được để trống.");
        }
        AiWasteClassificationHistory history = historyRepository.findById(historyId)
                .orElseThrow(() -> new IllegalArgumentException("Không tìm thấy lịch sử phân loại này."));
        return toDetailDto(history);
    }

    private ClassificationHistoryListItemDto toListItemDto(AiWasteClassificationHistory history) {
        return new ClassificationHistoryListItemDto(
                history.getHistoryId(),
                history.getTrashDetected(),
                history.getOverallConfidence(),
                history.getTotalObjectsDetected(),
                history.getOriginalImageUrl(),
                history.getCreatedAt());
    }

    private ClassificationHistoryDetailDto toDetailDto(AiWasteClassificationHistory history) {
        List<String> wasteTypes = parseJsonList(history.getWasteTypesJson(), new TypeReference<List<String>>() {
        });
        List<Map<String, Object>> detections = parseJsonList(history.getDetectionsJson(),
                new TypeReference<List<Map<String, Object>>>() {
                });

        return new ClassificationHistoryDetailDto(
                history.getHistoryId(),
                history.getTrashDetected(),
                history.getOverallConfidence(),
                history.getTotalObjectsDetected(),
                wasteTypes != null ? wasteTypes : new ArrayList<>(),
                history.getWasteTypesJson(),
                detections != null ? detections : new ArrayList<>(),
                history.getOriginalImageUrl(),
                history.getCreatedAt());
    }

    private <T> T parseJsonList(String json, TypeReference<T> typeReference) {
        if (json == null || json.isEmpty()) {
            return null;
        }
        try {
            return objectMapper.readValue(json, typeReference);
        } catch (JsonProcessingException ex) {
            return null;
        }
    }

    private String toJson(Object value) {
        if (value == null) {
            return null;
        }
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("Không thể serialize dữ liệu phân loại AI.", ex);
        }
    }
}
