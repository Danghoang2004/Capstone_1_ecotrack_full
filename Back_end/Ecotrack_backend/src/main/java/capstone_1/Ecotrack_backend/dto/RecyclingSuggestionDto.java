package capstone_1.Ecotrack_backend.dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class RecyclingSuggestionDto {
    private Long suggestionId;
    private String wasteCategory;
    private String title;
    private String description;
    private String imageUrl;
    private Integer suggestionOrder;
    private Boolean isActive;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
