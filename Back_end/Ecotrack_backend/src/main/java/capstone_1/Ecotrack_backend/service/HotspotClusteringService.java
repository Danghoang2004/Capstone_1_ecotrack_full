package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.HotspotClusterRequest;
import capstone_1.Ecotrack_backend.dto.response.HotspotClusterResponse;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service để gom nhóm báo cáo thành hotspot bằng DBSCAN
 * Gọi FastAPI Python để thực hiện clustering
 */
@Service
public class HotspotClusteringService {

    @Autowired
    private WasteReportRepository reportRepository;

    private final RestTemplate restTemplate = new RestTemplate();

    // URL của FastAPI
    private static final String FASTAPI_CLUSTER_URL = "http://localhost:8000/ai/cluster-hotspots";

    /**
     * Gom nhóm tất cả báo cáo từ kho dữ liệu
     * 
     * @param fromDate    Thời gian bắt đầu (tùy chọn)
     * @param toDate      Thời gian kết thúc (tùy chọn)
     * @param eps_km      Bán kính tối đa (km)
     * @param min_samples Số báo cáo tối thiểu để tạo hotspot
     * @return HotspotClusterResponse
     */
    public HotspotClusterResponse clusterAllReports(
            LocalDateTime fromDate,
            LocalDateTime toDate,
            Double eps_km,
            Integer min_samples) {

        // 1. Lấy tất cả báo cáo từ DB
        List<WasteReport> allReports = reportRepository.findAll();

        // 2. Filter báo cáo theo điều kiện
        List<HotspotClusterRequest.ReportCoordinate> coordinates = allReports.stream()
                .filter(r -> r.getStatus() == WasteReport.Status.VERIFIED) // Status VERIFIED
                .filter(r -> fromDate == null || r.getCreatedAt().isAfter(fromDate)
                        || r.getCreatedAt().isEqual(fromDate)) // >= fromDate
                .filter(r -> toDate == null || r.getCreatedAt().isBefore(toDate) || r.getCreatedAt().isEqual(toDate)) // <=
                                                                                                                      // toDate
                .map(r -> new HotspotClusterRequest.ReportCoordinate(
                        r.getReportId(),
                        r.getGpsLat().doubleValue(),
                        r.getGpsLong().doubleValue()))
                .collect(Collectors.toList());

        if (coordinates.isEmpty()) {
            return new HotspotClusterResponse(); // Empty response
        }

        // 3. Tạo request gửi sang FastAPI
        HotspotClusterRequest request = new HotspotClusterRequest(
                coordinates,
                eps_km != null ? eps_km : 0.5, // 500m mặc định
                min_samples != null ? min_samples : 2);

        // 4. Gọi FastAPI
        try {
            HotspotClusterResponse response = restTemplate.postForObject(
                    FASTAPI_CLUSTER_URL,
                    request,
                    HotspotClusterResponse.class);
            return response != null ? response : new HotspotClusterResponse();
        } catch (Exception e) {
            System.err.println("Lỗi gọi FastAPI DBSCAN: " + e.getMessage());
            return new HotspotClusterResponse();
        }
    }

    /**
     * Gom nhóm báo cáo trong một khu vực cụ thể (bounding box)
     * 
     * @param minLat,  maxLat, minLng, maxLng Bounding box
     * @param fromDate Thời gian bắt đầu (tùy chọn)
     * @param toDate   Thời gian kết thúc (tùy chọn)
     */
    public HotspotClusterResponse clusterReportsInArea(
            Double minLat, Double maxLat, Double minLng, Double maxLng,
            LocalDateTime fromDate,
            LocalDateTime toDate,
            Double eps_km,
            Integer min_samples) {

        // 1. Lấy báo cáo trong vùng và thời gian
        List<WasteReport> reportsInArea = reportRepository.findAll().stream()
                .filter(r -> r.getGpsLat().doubleValue() >= minLat &&
                        r.getGpsLat().doubleValue() <= maxLat &&
                        r.getGpsLong().doubleValue() >= minLng &&
                        r.getGpsLong().doubleValue() <= maxLng &&
                        r.getStatus() == WasteReport.Status.VERIFIED &&
                        (fromDate == null || r.getCreatedAt().isAfter(fromDate) || r.getCreatedAt().isEqual(fromDate))
                        &&
                        (toDate == null || r.getCreatedAt().isBefore(toDate) || r.getCreatedAt().isEqual(toDate)))
                .collect(Collectors.toList());

        if (reportsInArea.isEmpty()) {
            return new HotspotClusterResponse();
        }

        // 2. Chuyển sang tọa độ
        List<HotspotClusterRequest.ReportCoordinate> coordinates = reportsInArea.stream()
                .map(r -> new HotspotClusterRequest.ReportCoordinate(
                        r.getReportId(),
                        r.getGpsLat().doubleValue(),
                        r.getGpsLong().doubleValue()))
                .collect(Collectors.toList());

        // 3. Gửi request
        HotspotClusterRequest request = new HotspotClusterRequest(
                coordinates,
                eps_km != null ? eps_km : 0.5,
                min_samples != null ? min_samples : 2);

        try {
            return restTemplate.postForObject(
                    FASTAPI_CLUSTER_URL,
                    request,
                    HotspotClusterResponse.class);
        } catch (Exception e) {
            System.err.println("Lỗi clustering: " + e.getMessage());
            return new HotspotClusterResponse();
        }
    }
}
