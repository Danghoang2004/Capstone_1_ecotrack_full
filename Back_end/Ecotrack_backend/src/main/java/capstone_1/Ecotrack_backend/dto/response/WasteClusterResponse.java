package capstone_1.Ecotrack_backend.dto.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class WasteClusterResponse {
    private Double centerLat;
    private Double centerLng;
    private Long reportCount; // Số lượng báo cáo trong cụm này
    private String severityColor; // Màu sắc mức độ (VD: RED, ORANGE, YELLOW)
}