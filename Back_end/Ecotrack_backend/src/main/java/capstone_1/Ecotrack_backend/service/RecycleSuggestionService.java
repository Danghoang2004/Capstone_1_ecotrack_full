package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.RecycleSuggestionDetailDto;
import capstone_1.Ecotrack_backend.dto.response.RecycleSuggestionListItemDto;
import capstone_1.Ecotrack_backend.dto.response.RecycleSuggestionStepDto;
import capstone_1.Ecotrack_backend.model.RecycleSuggestion;
import capstone_1.Ecotrack_backend.model.RecycleSuggestionStep;
import capstone_1.Ecotrack_backend.repository.RecycleSuggestionRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.text.Normalizer;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class RecycleSuggestionService {

    private static final Logger log = LoggerFactory.getLogger(RecycleSuggestionService.class);

    private final RecycleSuggestionRepository recycleSuggestionRepository;

    public RecycleSuggestionService(RecycleSuggestionRepository recycleSuggestionRepository) {
        this.recycleSuggestionRepository = recycleSuggestionRepository;
    }

    @Transactional(readOnly = true)
    public List<RecycleSuggestionListItemDto> findSuggestionsByWasteTypes(List<String> wasteTypes) {
        Set<String> canonicalKeys = toCanonicalWasteTypeKeys(wasteTypes);
        if (canonicalKeys.isEmpty()) {
            throw new IllegalArgumentException("Danh sach loai rac khong hop le.");
        }

        List<RecycleSuggestion> suggestions = recycleSuggestionRepository
                .findByWasteTypeKeyInAndIsActiveTrueOrderByWasteTypeKeyAscSuggestionIdAsc(canonicalKeys);

        log.info("Recycle suggestion query: inputTypes={}, canonicalKeys={}, found={}",
                wasteTypes,
                canonicalKeys,
                suggestions.size());

        return suggestions.stream().map(this::toListItemDto).collect(Collectors.toList());
    }

    @Transactional(readOnly = true)
    public RecycleSuggestionDetailDto getSuggestionDetail(Long suggestionId) {
        if (suggestionId == null || suggestionId <= 0) {
            throw new IllegalArgumentException("ID goi y tai che khong hop le.");
        }

        RecycleSuggestion suggestion = recycleSuggestionRepository.findBySuggestionIdAndIsActiveTrue(suggestionId)
                .orElseThrow(() -> new IllegalArgumentException("Khong tim thay goi y tai che phu hop."));

        return toDetailDto(suggestion);
    }

    private Set<String> toCanonicalWasteTypeKeys(List<String> wasteTypes) {
        if (wasteTypes == null || wasteTypes.isEmpty()) {
            return Set.of();
        }

        Set<String> keys = new LinkedHashSet<>();
        for (String rawType : wasteTypes) {
            String normalized = normalizeType(rawType);
            if (normalized.isEmpty()) {
                continue;
            }

            keys.add(normalized);

            if (normalized.contains("nhua")) {
                keys.add("nhua");
            }
            if (normalized.contains("chai") && normalized.contains("nhua")) {
                keys.add("chai nhua");
            }
            if (normalized.contains("giay") || normalized.contains("bia")) {
                keys.add("giay");
            }
            if (normalized.contains("kim loai") || normalized.contains("lon")) {
                keys.add("kim loai");
            }
            if (normalized.contains("thuy tinh")) {
                keys.add("thuy tinh");
            }
            if (normalized.contains("huu co") || normalized.contains("thuc an")) {
                keys.add("huu co");
            }
        }

        return keys;
    }

    private String normalizeType(String rawType) {
        if (rawType == null) {
            return "";
        }

        return Normalizer.normalize(rawType, Normalizer.Form.NFD)
                .replaceAll("\\p{M}", "")
                .toLowerCase(Locale.ROOT)
                .replace('_', ' ')
                .replace('-', ' ')
                .replaceAll("\\s+", " ")
                .trim();
    }

    private RecycleSuggestionListItemDto toListItemDto(RecycleSuggestion suggestion) {
        RecycleSuggestionListItemDto dto = new RecycleSuggestionListItemDto();
        dto.setSuggestionId(suggestion.getSuggestionId());
        dto.setWasteTypeKey(suggestion.getWasteTypeKey());
        dto.setWasteTypeLabel(suggestion.getWasteTypeLabel());
        dto.setTitle(suggestion.getTitle());
        dto.setShortDescription(suggestion.getShortDescription());
        dto.setRecycleImageUrl(suggestion.getRecycleImageUrl());
        dto.setDifficultyLevel(suggestion.getDifficultyLevel());
        dto.setEstimatedTimeMinutes(suggestion.getEstimatedTimeMinutes());
        return dto;
    }

    private RecycleSuggestionDetailDto toDetailDto(RecycleSuggestion suggestion) {
        RecycleSuggestionDetailDto dto = new RecycleSuggestionDetailDto();
        dto.setSuggestionId(suggestion.getSuggestionId());
        dto.setWasteTypeKey(suggestion.getWasteTypeKey());
        dto.setWasteTypeLabel(suggestion.getWasteTypeLabel());
        dto.setTitle(suggestion.getTitle());
        dto.setShortDescription(suggestion.getShortDescription());
        dto.setRecycleImageUrl(suggestion.getRecycleImageUrl());
        dto.setDifficultyLevel(suggestion.getDifficultyLevel());
        dto.setEstimatedTimeMinutes(suggestion.getEstimatedTimeMinutes());
        dto.setMaterialsNeeded(suggestion.getMaterialsNeeded());

        List<RecycleSuggestionStepDto> stepDtos = new ArrayList<>();
        for (RecycleSuggestionStep step : suggestion.getSteps()) {
            RecycleSuggestionStepDto stepDto = new RecycleSuggestionStepDto();
            stepDto.setStepOrder(step.getStepOrder());
            stepDto.setStepTitle(step.getStepTitle());
            stepDto.setStepDescription(step.getStepDescription());
            stepDto.setInstructionImageUrl(step.getInstructionImageUrl());
            stepDto.setInstructionVideoUrl(step.getInstructionVideoUrl());
            stepDtos.add(stepDto);
        }
        dto.setSteps(stepDtos);

        return dto;
    }
}
