package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class GetAllUserResponse {
    private Long id;
    private String fullName;
    private String email;
    private String username;
    private String avatarUrl;
    private String location;
    private Integer points;
    private Integer rank;
    private Integer reports; // Số báo cáo rác
    private Integer campaigns; // Số chiến dịch (groups)
    private Boolean isActive; // Trạng thái hoạt động
}

