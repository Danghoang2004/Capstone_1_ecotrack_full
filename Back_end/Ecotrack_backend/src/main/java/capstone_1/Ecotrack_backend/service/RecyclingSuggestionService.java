package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.RecyclingSuggestionDto;
import capstone_1.Ecotrack_backend.model.RecyclingSuggestion;
import capstone_1.Ecotrack_backend.repository.RecyclingSuggestionRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RecyclingSuggestionService {

    @Autowired
    private RecyclingSuggestionRepository recyclingSuggestionRepository;

    /**
     * Lấy danh sách gợi ý tái chế theo loại rác (US05 + US07)
     * @param wasteCategory loại rác
     * @return danh sách gợi ý
     */
    public List<RecyclingSuggestionDto> getSuggestionsByCategory(String wasteCategory) {
        List<RecyclingSuggestion> suggestions =
            recyclingSuggestionRepository.findByWasteCategoryAndIsActiveTrueOrderBySuggestionOrderAsc(wasteCategory);
        return suggestions.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }

    /**
     * Lấy tất cả gợi ý tái chế
     * @return danh sách tất cả gợi ý
     */
    public List<RecyclingSuggestionDto> getAllActiveSuggestions() {
        List<RecyclingSuggestion> suggestions =
            recyclingSuggestionRepository.findByIsActiveTrueOrderByWasteCategoryAscSuggestionOrderAsc();
        return suggestions.stream()
            .map(this::convertToDto)
            .collect(Collectors.toList());
    }

    /**
     * Tạo gợi ý mới (Admin)
     * @param suggestionDto DTO chứa thông tin gợi ý
     * @return gợi ý đã tạo
     */
    public RecyclingSuggestionDto createSuggestion(RecyclingSuggestionDto suggestionDto) {
        RecyclingSuggestion suggestion = new RecyclingSuggestion();
        suggestion.setWasteCategory(suggestionDto.getWasteCategory());
        suggestion.setTitle(suggestionDto.getTitle());
        suggestion.setDescription(suggestionDto.getDescription());
        suggestion.setImageUrl(suggestionDto.getImageUrl());
        suggestion.setSuggestionOrder(suggestionDto.getSuggestionOrder() != null ? suggestionDto.getSuggestionOrder() : 0);
        suggestion.setIsActive(true);

        RecyclingSuggestion saved = recyclingSuggestionRepository.save(suggestion);
        return convertToDto(saved);
    }

    /**
     * Cập nhật gợi ý (Admin)
     * @param suggestionId ID gợi ý
     * @param suggestionDto DTO chứa thông tin cập nhật
     * @return gợi ý đã cập nhật
     */
    public RecyclingSuggestionDto updateSuggestion(Long suggestionId, RecyclingSuggestionDto suggestionDto) {
        RecyclingSuggestion suggestion = recyclingSuggestionRepository.findById(suggestionId)
            .orElseThrow(() -> new RuntimeException("Gợi ý không tìm thấy"));

        suggestion.setWasteCategory(suggestionDto.getWasteCategory());
        suggestion.setTitle(suggestionDto.getTitle());
        suggestion.setDescription(suggestionDto.getDescription());
        suggestion.setImageUrl(suggestionDto.getImageUrl());
        suggestion.setSuggestionOrder(suggestionDto.getSuggestionOrder());
        suggestion.setIsActive(suggestionDto.getIsActive());

        RecyclingSuggestion updated = recyclingSuggestionRepository.save(suggestion);
        return convertToDto(updated);
    }

    /**
     * Xóa gợi ý (Admin)
     * @param suggestionId ID gợi ý
     */
    public void deleteSuggestion(Long suggestionId) {
        recyclingSuggestionRepository.deleteById(suggestionId);
    }

    /**
     * Convert Entity to DTO
     */
    private RecyclingSuggestionDto convertToDto(RecyclingSuggestion suggestion) {
        RecyclingSuggestionDto dto = new RecyclingSuggestionDto();
        dto.setSuggestionId(suggestion.getSuggestionId());
        dto.setWasteCategory(suggestion.getWasteCategory());
        dto.setTitle(suggestion.getTitle());
        dto.setDescription(suggestion.getDescription());
        dto.setImageUrl(suggestion.getImageUrl());
        dto.setSuggestionOrder(suggestion.getSuggestionOrder());
        dto.setIsActive(suggestion.getIsActive());
        dto.setCreatedAt(suggestion.getCreatedAt());
        dto.setUpdatedAt(suggestion.getUpdatedAt());
        return dto;
    }
}
