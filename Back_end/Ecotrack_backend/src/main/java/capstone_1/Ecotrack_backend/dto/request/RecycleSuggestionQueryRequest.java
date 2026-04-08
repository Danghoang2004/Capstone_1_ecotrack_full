package capstone_1.Ecotrack_backend.dto.request;

import jakarta.validation.constraints.NotEmpty;

import java.util.List;

public class RecycleSuggestionQueryRequest {

    @NotEmpty(message = "Danh sách loại rác không được để trống.")
    private List<String> wasteTypes;

    public List<String> getWasteTypes() {
        return wasteTypes;
    }

    public void setWasteTypes(List<String> wasteTypes) {
        this.wasteTypes = wasteTypes;
    }
}
