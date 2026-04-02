package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.response.ClusterProjection;
import capstone_1.Ecotrack_backend.dto.response.WasteClusterResponse;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class MapClusterService {

    private final WasteReportRepository wasteReportRepository;

    public List<WasteClusterResponse> getClusteredHotspots() {
        List<ClusterProjection> clusters = wasteReportRepository.findWasteClusters();

        return clusters.stream().map(cluster -> {
            String color;
            long count = cluster.getReportCount();

            // Phân loại mức độ dựa trên số lượng rác trong bán kính 110m
            if (count >= 5) {
                color = "#FF0000"; // Đỏ (Nghiêm trọng)
            } else if (count >= 2) {
                color = "#FFA500"; // Cam (Cảnh báo)
            } else {
                color = "#FFFF00"; // Vàng (Nhẹ)
            }

            return new WasteClusterResponse(
                    cluster.getCenterLat(),
                    cluster.getCenterLng(),
                    count,
                    color
            );
        }).collect(Collectors.toList());
    }
}