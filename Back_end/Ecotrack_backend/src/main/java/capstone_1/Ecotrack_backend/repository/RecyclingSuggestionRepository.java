package capstone_1.Ecotrack_backend.repository;

import capstone_1.Ecotrack_backend.model.RecyclingSuggestion;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface RecyclingSuggestionRepository extends JpaRepository<RecyclingSuggestion, Long> {

    /**
     * Lấy tất cả gợi ý tái chế theo loại rác và sắp xếp theo thứ tự
     * @param wasteCategory loại rác (NHUA, HUU_CO, KIM_LOAI, XAY_DUNG, KHAC)
     * @return danh sách gợi ý tái chế
     */
    List<RecyclingSuggestion> findByWasteCategoryAndIsActiveTrueOrderBySuggestionOrderAsc(String wasteCategory);

    /**
     * Lấy tất cả gợi ý tái chế
     * @return danh sách tất cả gợi ý
     */
    List<RecyclingSuggestion> findByIsActiveTrueOrderByWasteCategoryAscSuggestionOrderAsc();

    /**
     * Lấy gợi ý theo loại rác (kể cả những cái bị vô hiệu)
     * @param wasteCategory loại rác
     * @return danh sách gợi ý
     */
    List<RecyclingSuggestion> findByWasteCategoryOrderBySuggestionOrderAsc(String wasteCategory);

    /**
     * Kiểm tra xem có gợi ý nào cho loại rác không
     * @param wasteCategory loại rác
     * @return true nếu có, false nếu không
     */
    boolean existsByWasteCategory(String wasteCategory);
}
