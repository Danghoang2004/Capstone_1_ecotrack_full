package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.SuggestionResponseDTO;
import java.util.List;

public interface RecyclingSuggestionService {
    List<SuggestionResponseDTO> getSuggestionsByCategory(String wasteCategory);
    List<SuggestionResponseDTO> getSuggestionsByReportId(Long reportId);
}