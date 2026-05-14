package capstone_1.Ecotrack_backend.dto.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class AwardBadgeRequest {
    private Long userId;
    private Long badgeId;
}
