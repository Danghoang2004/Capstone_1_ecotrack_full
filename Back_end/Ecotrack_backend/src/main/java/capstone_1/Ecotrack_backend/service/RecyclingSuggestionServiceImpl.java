package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.SuggestionResponseDTO;
import capstone_1.Ecotrack_backend.model.RecyclingSuggestion;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.RecyclingSuggestionRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;
import java.util.Optional;

@Service
public class RecyclingSuggestionServiceImpl implements RecyclingSuggestionService {

    @Autowired
    private RecyclingSuggestionRepository suggestionRepository;
    @Autowired
        private WasteReportRepository wasteReportRepository;

    @Override
    public List<SuggestionResponseDTO> getSuggestionsByCategory(String wasteCategory) {
        String formattedCategory = wasteCategory.trim().toUpperCase();
        List<RecyclingSuggestion> suggestions = suggestionRepository.findByWasteCategory(formattedCategory);

        return suggestions.stream().map(suggestion -> new SuggestionResponseDTO(
                suggestion.getTitle(),
                suggestion.getDescription(),
                suggestion.getImageUrl()
        )).collect(Collectors.toList());
    }
    @Override
    public List<SuggestionResponseDTO> getSuggestionsByReportId(Long reportId) {
        // 1. Tìm Report trong DB dựa vào ID
        Optional<WasteReport> reportOpt = wasteReportRepository.findById(reportId);
        
        if (reportOpt.isEmpty() || reportOpt.get().getCategory() == null) {
            // Trả về list rỗng nếu không tìm thấy report hoặc report chưa có category AI
            return List.of(); 
        }

        // 2. Lấy được nhãn AI đã phân loại và lưu (VD: "NHUA", "KIM_LOAI")
        String aiCategory = reportOpt.get().getCategory().trim().toUpperCase();

        // 3. Tìm các gợi ý dựa trên nhãn đó (Tái sử dụng Repository đã có)
        List<RecyclingSuggestion> suggestions = suggestionRepository.findByWasteCategory(aiCategory);

        // 4. Map sang DTO trả về cho App
        return suggestions.stream().map(suggestion -> new SuggestionResponseDTO(
                suggestion.getTitle(),
                suggestion.getDescription(),
                suggestion.getImageUrl()
        )).collect(Collectors.toList());
    }
}