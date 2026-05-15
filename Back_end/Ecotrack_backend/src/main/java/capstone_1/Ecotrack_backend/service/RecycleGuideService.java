package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.AdminRecycleGuideUpsertRequest;
import capstone_1.Ecotrack_backend.dto.request.AdminRecycleStepUpsertRequest;
import capstone_1.Ecotrack_backend.dto.response.AdminRecycleGuideResponse;
import capstone_1.Ecotrack_backend.model.RecycleSuggestion;
import capstone_1.Ecotrack_backend.model.RecycleSuggestionStep;
import capstone_1.Ecotrack_backend.repository.RecycleSuggestionRepository;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.server.ResponseStatusException;
import org.springframework.http.HttpStatus;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class RecycleGuideService {

    private final RecycleSuggestionRepository repo;

    public RecycleGuideService(RecycleSuggestionRepository repo) {
        this.repo = repo;
    }

    @Transactional(readOnly = true)
    public List<AdminRecycleGuideResponse> listAll() {
        List<RecycleSuggestion> suggestions = repo.findAll(Sort.by(Sort.Direction.ASC, "suggestionId"));
        List<AdminRecycleGuideResponse> responses = new ArrayList<>();
        for (RecycleSuggestion suggestion : suggestions) {
            responses.add(toResponse(suggestion));
        }
        return responses;
    }

    @Transactional
    public AdminRecycleGuideResponse create(AdminRecycleGuideUpsertRequest request) {
        validateRequest(request);
        RecycleSuggestion suggestion = new RecycleSuggestion();
        applyRequestToSuggestion(suggestion, request);
        return toResponse(repo.save(suggestion));
    }

    @Transactional(readOnly = true)
    public Optional<AdminRecycleGuideResponse> findById(Long id) {
        return repo.findById(id).map(this::toResponse);
    }

    @Transactional
    public AdminRecycleGuideResponse update(Long id, AdminRecycleGuideUpsertRequest request) {
        validateRequest(request);
        RecycleSuggestion suggestion = repo.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy hướng dẫn tái chế."));
        applyRequestToSuggestion(suggestion, request);
        return toResponse(repo.save(suggestion));
    }

    @Transactional
    public void delete(Long id) {
        if (!repo.existsById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Không tìm thấy hướng dẫn tái chế.");
        }
        repo.deleteById(id);
    }

    private void validateRequest(AdminRecycleGuideUpsertRequest request) {
        if (!StringUtils.hasText(request.getWasteTypeKey())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu wasteTypeKey.");
        }
        if (!StringUtils.hasText(request.getWasteTypeLabel())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu wasteTypeLabel.");
        }
        if (!StringUtils.hasText(request.getName())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tên hướng dẫn.");
        }
        if (!StringUtils.hasText(request.getImageUrl())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu ảnh đại diện hướng dẫn (imageUrl).");
        }
        if (!StringUtils.hasText(request.getMaterialsNeeded())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu materialsNeeded.");
        }
        if (request.getSteps() == null || request.getSteps().isEmpty()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Cần ít nhất 1 bước hướng dẫn.");
        }

        for (int i = 0; i < request.getSteps().size(); i++) {
            AdminRecycleStepUpsertRequest step = request.getSteps().get(i);
            if (!StringUtils.hasText(step.getStepTitle())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu tiêu đề ở bước " + (i + 1) + ".");
            }
            if (!StringUtils.hasText(step.getStepDescription())) {
                throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Thiếu mô tả ở bước " + (i + 1) + ".");
            }
        }
    }

    private void applyRequestToSuggestion(RecycleSuggestion suggestion, AdminRecycleGuideUpsertRequest request) {
        suggestion.setWasteTypeKey(request.getWasteTypeKey().trim());
        suggestion.setWasteTypeLabel(request.getWasteTypeLabel().trim());
        suggestion.setTitle(request.getName().trim());
        suggestion.setShortDescription(request.getDescription() == null ? "" : request.getDescription().trim());
        suggestion.setRecycleImageUrl(request.getImageUrl().trim());
        suggestion.setDifficultyLevel(request.getDifficultyLevel());
        suggestion.setEstimatedTimeMinutes(request.getEstimatedTimeMinutes());
        suggestion.setMaterialsNeeded(request.getMaterialsNeeded().trim());
        suggestion.setIsActive(request.getIsActive() == null ? Boolean.TRUE : request.getIsActive());

        suggestion.getSteps().clear();
        List<AdminRecycleStepUpsertRequest> requestSteps = request.getSteps();
        for (int i = 0; i < requestSteps.size(); i++) {
            AdminRecycleStepUpsertRequest requestStep = requestSteps.get(i);
            RecycleSuggestionStep step = new RecycleSuggestionStep();
            step.setSuggestion(suggestion);
            step.setStepOrder(i + 1);
            step.setStepTitle(requestStep.getStepTitle().trim());
            step.setStepDescription(requestStep.getStepDescription().trim());
            step.setInstructionImageUrl(toNullableTrim(requestStep.getInstructionImageUrl()));
            step.setInstructionVideoUrl(toNullableTrim(requestStep.getInstructionVideoUrl()));
            suggestion.getSteps().add(step);
        }
    }

    private String toNullableTrim(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        return value.trim();
    }

    private AdminRecycleGuideResponse toResponse(RecycleSuggestion suggestion) {
        AdminRecycleGuideResponse response = new AdminRecycleGuideResponse();
        response.setGuideId(suggestion.getSuggestionId());
        response.setWasteTypeKey(suggestion.getWasteTypeKey());
        response.setWasteTypeLabel(suggestion.getWasteTypeLabel());
        response.setName(suggestion.getTitle());
        response.setDescription(suggestion.getShortDescription());
        response.setImageUrl(suggestion.getRecycleImageUrl());
        response.setDifficultyLevel(suggestion.getDifficultyLevel());
        response.setEstimatedTimeMinutes(suggestion.getEstimatedTimeMinutes());
        response.setMaterialsNeeded(suggestion.getMaterialsNeeded());
        response.setIsActive(suggestion.getIsActive());
        response.setStepCount(suggestion.getSteps() == null ? 0 : suggestion.getSteps().size());

        List<AdminRecycleGuideResponse.AdminRecycleStepResponse> stepResponses = new ArrayList<>();
        if (suggestion.getSteps() != null) {
            for (RecycleSuggestionStep step : suggestion.getSteps()) {
                AdminRecycleGuideResponse.AdminRecycleStepResponse stepResponse =
                        new AdminRecycleGuideResponse.AdminRecycleStepResponse();
                stepResponse.setStepId(step.getStepId());
                stepResponse.setStepOrder(step.getStepOrder());
                stepResponse.setStepTitle(step.getStepTitle());
                stepResponse.setStepDescription(step.getStepDescription());
                stepResponse.setInstructionImageUrl(step.getInstructionImageUrl());
                stepResponse.setInstructionVideoUrl(step.getInstructionVideoUrl());
                stepResponses.add(stepResponse);
            }
        }
        response.setSteps(stepResponses);
        return response;
    }
}
