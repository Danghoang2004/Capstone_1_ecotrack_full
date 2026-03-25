package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.HotspotClusterRequest;
import capstone_1.Ecotrack_backend.dto.response.HotspotClusterResponse;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.client.RestClientException;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Service để gom nhóm báo cáo thành hotspot bằng DBSCAN
 * Gọi FastAPI Python để thực hiện clustering
 */
@Service
@Slf4j
public class HotspotClusteringService {

        @Autowired
        private WasteReportRepository reportRepository;

        @Autowired
        private RestTemplate restTemplate;

        // Configuration từ application.properties
        @Value("${hotspot.fastapi.url:http://localhost:8000/ai/cluster-hotspots}")
        private String FASTAPI_CLUSTER_URL;

        @Value("${hotspot.default.eps-km:0.5}")
        private Double DEFAULT_EPS_KM;

        @Value("${hotspot.default.min-samples:2}")
        private Integer DEFAULT_MIN_SAMPLES;

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

                log.info("Bắt đầu clustering tất cả báo cáo. fromDate={}, toDate={}, eps_km={}, min_samples={}",
                                fromDate, toDate, eps_km, min_samples);

                try {
                        // 1. Lấy báo cáo VERIFIED từ DB với custom query (tối ưu)
                        List<WasteReport> allReports = reportRepository.findVerifiedReports(fromDate, toDate);

                        log.debug("Tìm thấy {} báo cáo VERIFIED", allReports.size());

                        if (allReports.isEmpty()) {
                                log.warn("Không có báo cáo VERIFIED nào để clustering");
                                return new HotspotClusterResponse();
                        }

                        // 2. Chuyển sang tọa độ
                        List<HotspotClusterRequest.ReportCoordinate> coordinates = allReports.stream()
                                        .map(r -> new HotspotClusterRequest.ReportCoordinate(
                                                        r.getReportId(),
                                                        r.getGpsLat().doubleValue(),
                                                        r.getGpsLong().doubleValue()))
                                        .collect(Collectors.toList());

                        log.debug("Đã trích xuất {} tọa độ báo cáo", coordinates.size());

                        // 3. Tạo request gửi sang FastAPI
                        Double finalEpsKm = eps_km != null ? eps_km : DEFAULT_EPS_KM;
                        Integer finalMinSamples = min_samples != null ? min_samples : DEFAULT_MIN_SAMPLES;

                        HotspotClusterRequest request = new HotspotClusterRequest(
                                        coordinates,
                                        finalEpsKm,
                                        finalMinSamples);

                        log.debug("Gửi request tới FastAPI: URL={}, eps_km={}, min_samples={}",
                                        FASTAPI_CLUSTER_URL, finalEpsKm, finalMinSamples);

                        // 4. Gọi FastAPI
                        HotspotClusterResponse response = restTemplate.postForObject(
                                        FASTAPI_CLUSTER_URL,
                                        request,
                                        HotspotClusterResponse.class);

                        if (response != null && response.getSuccess() != null && response.getSuccess()) {
                                log.info("Clustering thành công. Tổng hotspot: {}, noise points: {}",
                                                response.getTotal_clusters(), response.getNoise_points());
                        } else {
                                log.warn("FastAPI trả về response không thành công hoặc null");
                        }

                        return response != null ? response : new HotspotClusterResponse();

                } catch (RestClientException e) {
                        log.error("Lỗi kết nối FastAPI: {}", e.getMessage(), e);
                        return new HotspotClusterResponse();
                } catch (Exception e) {
                        log.error("Lỗi không mong muốn khi clustering: {}", e.getMessage(), e);
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

                log.info("Bắt đầu clustering trong vùng. Box: ({},{}) - ({},{}), fromDate={}, toDate={}, eps_km={}, min_samples={}",
                                minLat, minLng, maxLat, maxLng, fromDate, toDate, eps_km, min_samples);

                try {
                        // 1. Lấy báo cáo trong vùng với custom query (tối ưu)
                        List<WasteReport> reportsInArea = reportRepository.findVerifiedReportsInArea(
                                        minLat, maxLat, minLng, maxLng, fromDate, toDate);

                        log.debug("Tìm thấy {} báo cáo VERIFIED trong vùng", reportsInArea.size());

                        if (reportsInArea.isEmpty()) {
                                log.warn("Không có báo cáo VERIFIED nào trong vùng được chỉ định");
                                return new HotspotClusterResponse();
                        }

                        // 2. Chuyển sang tọa độ
                        List<HotspotClusterRequest.ReportCoordinate> coordinates = reportsInArea.stream()
                                        .map(r -> new HotspotClusterRequest.ReportCoordinate(
                                                        r.getReportId(),
                                                        r.getGpsLat().doubleValue(),
                                                        r.getGpsLong().doubleValue()))
                                        .collect(Collectors.toList());

                        log.debug("Đã trích xuất {} tọa độ báo cáo từ vùng", coordinates.size());

                        // 3. Tạo request
                        Double finalEpsKm = eps_km != null ? eps_km : DEFAULT_EPS_KM;
                        Integer finalMinSamples = min_samples != null ? min_samples : DEFAULT_MIN_SAMPLES;

                        HotspotClusterRequest request = new HotspotClusterRequest(
                                        coordinates,
                                        finalEpsKm,
                                        finalMinSamples);

                        log.debug("Gửi request tới FastAPI: URL={}, eps_km={}, min_samples={}",
                                        FASTAPI_CLUSTER_URL, finalEpsKm, finalMinSamples);

                        // 4. Gửi request
                        HotspotClusterResponse response = restTemplate.postForObject(
                                        FASTAPI_CLUSTER_URL,
                                        request,
                                        HotspotClusterResponse.class);

                        if (response != null && response.getSuccess() != null && response.getSuccess()) {
                                log.info("Clustering vùng thành công. Tổng hotspot: {}, noise points: {}",
                                                response.getTotal_clusters(), response.getNoise_points());
                        } else {
                                log.warn("FastAPI trả về response không thành công hoặc null");
                        }

                        return response != null ? response : new HotspotClusterResponse();

                } catch (RestClientException e) {
                        log.error("Lỗi kết nối FastAPI: {}", e.getMessage(), e);
                        return new HotspotClusterResponse();
                } catch (Exception e) {
                        log.error("Lỗi không mong muốn khi clustering vùng: {}", e.getMessage(), e);
                        return new HotspotClusterResponse();
                }
        }
}
