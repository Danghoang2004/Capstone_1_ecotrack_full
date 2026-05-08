package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class BadgeProgressResponse {
    private Integer currentPoints;
    private List<BadgeResponse> badges;
}
