package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class RankingGroupResponse {
    private String id;
    private Integer rank;
    private String groupName;
    private Integer points;
    private String logoUrl;
    private String location;
    private List<String> titles; // Badge titles
    private Integer members; // Số thành viên
    private Integer activities; // Số hoạt động
}

