package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RankingUserResponse {
    private String id;
    private Integer rank;
    private String userName;
    private Integer points;
    private String avatarUrl;
    private String location;
    private List<String> titles; // Badge titles
    private Integer activities; // Số hoạt động (reports)
    private Integer badges; // Số huy hiệu
}

