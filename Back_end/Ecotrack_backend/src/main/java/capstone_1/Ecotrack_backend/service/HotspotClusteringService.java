package capstone_1.Ecotrack_backend.service;

import capstone_1.Ecotrack_backend.dto.request.HotspotClusterRequest;
import capstone_1.Ecotrack_backend.dto.request.HotspotPredictRequest;
import capstone_1.Ecotrack_backend.dto.response.HotspotClusterResponse;
import capstone_1.Ecotrack_backend.dto.response.HotspotNearbyResponse;
import capstone_1.Ecotrack_backend.dto.response.HotspotPredictResponse;
import capstone_1.Ecotrack_backend.model.RecycleSuggestion;
import capstone_1.Ecotrack_backend.model.RecycleSuggestionStep;
import capstone_1.Ecotrack_backend.model.WasteReport;
import capstone_1.Ecotrack_backend.repository.RecycleSuggestionRepository;
import capstone_1.Ecotrack_backend.repository.WasteReportRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.text.Normalizer;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.stream.Collectors;

/**
 * Service để gom nhóm báo cáo thành hotspot bằng DBSCAN
 * Gọi FastAPI Python để thực hiện clustering
 */
@Service
public class HotspotClusteringService {

        @Autowired
        private WasteReportRepository reportRepository;

        @Autowired
        private RecycleSuggestionRepository recycleSuggestionRepository;

        private final RestTemplate restTemplate = new RestTemplate();

        // URL của FastAPI
        @Value("${ai.cluster-hotspots-url}")
        private String fastApiClusterUrl;

        @Value("${ai.predict-hotspots-url}")
        private String fastApiPredictUrl;

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
                                .filter(r -> toDate == null || r.getCreatedAt().isBefore(toDate)
                                                || r.getCreatedAt().isEqual(toDate)) // <=
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
                                        fastApiClusterUrl,
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
                                                (fromDate == null || r.getCreatedAt().isAfter(fromDate)
                                                                || r.getCreatedAt().isEqual(fromDate))
                                                &&
                                                (toDate == null || r.getCreatedAt().isBefore(toDate)
                                                                || r.getCreatedAt().isEqual(toDate)))
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
                                        fastApiClusterUrl,
                                        request,
                                        HotspotClusterResponse.class);
                } catch (Exception e) {
                        System.err.println("Lỗi clustering: " + e.getMessage());
                        return new HotspotClusterResponse();
                }
        }

        public HotspotNearbyResponse findNearbyHotspots(
                        Double lat,
                        Double lng,
                        Double alertRadiusMeters,
                        Double epsKm,
                        Integer minSamples) {
                double radiusMeters = alertRadiusMeters != null ? alertRadiusMeters : 250.0;
                HotspotClusterResponse clustered = clusterAllReports(null, null, epsKm, minSamples);
                List<HotspotNearbyResponse.NearbyHotspot> nearby = new ArrayList<>();

                if (clustered.getHotspots() != null) {
                        for (HotspotClusterResponse.Hotspot hotspot : clustered.getHotspots()) {
                                if (hotspot.getCenter_lat() == null || hotspot.getCenter_lng() == null) {
                                        continue;
                                }

                                double distanceMeters = haversineMeters(
                                                lat,
                                                lng,
                                                hotspot.getCenter_lat(),
                                                hotspot.getCenter_lng());
                                double hotspotRadiusMeters = hotspot.getRadius_km() != null
                                                ? hotspot.getRadius_km() * 1000.0
                                                : 0.0;

                                if (distanceMeters > radiusMeters + hotspotRadiusMeters) {
                                        continue;
                                }

                                HotspotNearbyResponse.NearbyHotspot item = new HotspotNearbyResponse.NearbyHotspot();
                                item.setClusterId(hotspot.getCluster_id());
                                item.setCenterLat(hotspot.getCenter_lat());
                                item.setCenterLng(hotspot.getCenter_lng());
                                item.setRadiusKm(hotspot.getRadius_km());
                                item.setReportCount(hotspot.getReport_count());
                                item.setDistanceMeters(distanceMeters);

                                List<Long> reportIds = hotspot.getReport_ids() != null
                                                ? hotspot.getReport_ids()
                                                : List.of();
                                List<WasteReport> reportsInHotspot = reportRepository.findAllById(reportIds);
                                
                                Map<String, Long> categoryCounts = reportsInHotspot.stream()
                                                .map(WasteReport::getCategory)
                                                .filter(Objects::nonNull)
                                                .map(String::trim)
                                                .filter(category -> !category.isEmpty())
                                                .collect(Collectors.groupingBy(
                                                                category -> category,
                                                                Collectors.counting()));
                                item.setCategoryCounts(categoryCounts);
                                
                                // Set reports list
                                List<HotspotNearbyResponse.ReportInfo> reportInfos = reportsInHotspot.stream()
                                                .map(r -> new HotspotNearbyResponse.ReportInfo(
                                                        r.getReportId(),
                                                        r.getTitle() != null ? r.getTitle() : "Không có tiêu đề",
                                                        r.getDescription() != null ? r.getDescription() : "",
                                                        r.getCategory() != null ? r.getCategory() : "Rác hỗn hợp",
                                                        r.getStatus() != null ? r.getStatus().name() : "UNKNOWN"
                                                ))
                                                .collect(Collectors.toList());
                                item.setReports(reportInfos);

                                String dominantWasteType = categoryCounts.entrySet().stream()
                                                .max(Map.Entry.comparingByValue())
                                                .map(Map.Entry::getKey)
                                                .orElse("Rác hỗn hợp");
                                item.setDominantWasteType(dominantWasteType);
                                item.setRecyclingSuggestion(buildRecyclingSuggestion(dominantWasteType));

                                nearby.add(item);
                        }
                }

                nearby.sort(Comparator.comparing(HotspotNearbyResponse.NearbyHotspot::getDistanceMeters));

                HotspotNearbyResponse response = new HotspotNearbyResponse();
                response.setSuccess(true);
                response.setHotspots(nearby);
                response.setNearestHotspot(nearby.isEmpty() ? null : nearby.get(0));
                response.setAlert(!nearby.isEmpty());
                return response;
        }

        private HotspotNearbyResponse.RecyclingSuggestion buildRecyclingSuggestion(String wasteType) {
                HotspotNearbyResponse.RecyclingSuggestion suggestionFromDb = buildRecyclingSuggestionFromDb(wasteType);
                if (suggestionFromDb != null) {
                        return suggestionFromDb;
                }

                String normalized = wasteType == null ? "" : wasteType.toLowerCase();

                if (normalized.contains("plastic") || normalized.contains("nhựa") || normalized.contains("chai")) {
                        return new HotspotNearbyResponse.RecyclingSuggestion(
                                        "Tái chế rác nhựa",
                                        List.of(
                                                        "Làm rỗng chai, hộp nhựa và tráng nhanh nếu còn thức ăn hoặc đồ uống.",
                                                        "Tháo nắp, ép dẹp chai để giảm thể tích.",
                                                        "Bỏ vào thùng tái chế nhựa hoặc gom riêng để giao cho điểm thu hồi."));
                }

                if (normalized.contains("paper") || normalized.contains("giấy") || normalized.contains("carton")) {
                        return new HotspotNearbyResponse.RecyclingSuggestion(
                                        "Tái chế giấy và bìa carton",
                                        List.of(
                                                        "Giữ giấy khô, không lẫn dầu mỡ hoặc thức ăn.",
                                                        "Gấp gọn thùng carton trước khi bỏ vào điểm thu gom.",
                                                        "Tách giấy bẩn, khăn giấy và giấy phủ nhựa khỏi nhóm tái chế."));
                }

                if (normalized.contains("glass") || normalized.contains("thủy tinh")
                                || normalized.contains("chai lọ")) {
                        return new HotspotNearbyResponse.RecyclingSuggestion(
                                        "Tái chế thủy tinh",
                                        List.of(
                                                        "Đổ hết chất lỏng còn lại và tráng sơ chai lọ.",
                                                        "Bọc mảnh vỡ sắc nhọn trước khi bỏ vào nơi thu gom.",
                                                        "Không trộn bóng đèn, gốm sứ hoặc kính vỡ với chai lọ tái chế."));
                }

                if (normalized.contains("metal") || normalized.contains("kim loại") || normalized.contains("lon")) {
                        return new HotspotNearbyResponse.RecyclingSuggestion(
                                        "Tái chế kim loại",
                                        List.of(
                                                        "Làm rỗng lon và hộp kim loại.",
                                                        "Ép dẹp lon nếu có thể để tiết kiệm không gian.",
                                                        "Gom riêng pin hoặc bình xịt vì cần xử lý như rác nguy hại."));
                }

                if (normalized.contains("organic") || normalized.contains("hữu cơ") || normalized.contains("thức ăn")) {
                        return new HotspotNearbyResponse.RecyclingSuggestion(
                                        "Xử lý rác hữu cơ",
                                        List.of(
                                                        "Tách rác hữu cơ khỏi nhựa, kim loại và thủy tinh.",
                                                        "Ưu tiên ủ compost nếu khu vực có điểm tiếp nhận.",
                                                        "Buộc kín phần dễ gây mùi nếu chưa thể xử lý ngay."));
                }

                return new HotspotNearbyResponse.RecyclingSuggestion(
                                "Phân loại rác hỗn hợp",
                                List.of(
                                                "Tách vật sắc nhọn, pin và rác nguy hại ra khỏi túi rác chung.",
                                                "Gom riêng nhựa, giấy, kim loại hoặc thủy tinh còn sạch để tái chế.",
                                                "Dùng găng tay khi dọn và báo lại trạng thái sau khi hoàn thành."));
        }

        private HotspotNearbyResponse.RecyclingSuggestion buildRecyclingSuggestionFromDb(String wasteType) {
                Set<String> keys = toCanonicalWasteTypeKeys(wasteType);
                if (keys.isEmpty()) {
                        return null;
                }

                List<RecycleSuggestion> suggestions = recycleSuggestionRepository
                                .findByWasteTypeKeyInAndIsActiveTrueOrderByWasteTypeKeyAscSuggestionIdAsc(keys);
                if (suggestions.isEmpty()) {
                        return null;
                }

                RecycleSuggestion suggestion = suggestions.get(0);
                List<String> steps = suggestion.getSteps() == null
                                ? List.of()
                                : suggestion.getSteps().stream()
                                                .sorted(Comparator.comparing(
                                                                RecycleSuggestionStep::getStepOrder,
                                                                Comparator.nullsLast(Integer::compareTo)))
                                                .map(step -> {
                                                        String title = step.getStepTitle() == null ? ""
                                                                        : step.getStepTitle().trim();
                                                        String description = step.getStepDescription() == null ? ""
                                                                        : step.getStepDescription().trim();
                                                        if (title.isEmpty()) {
                                                                return description;
                                                        }
                                                        if (description.isEmpty()) {
                                                                return title;
                                                        }
                                                        return title + ": " + description;
                                                })
                                                .filter(step -> step != null && !step.isBlank())
                                                .limit(4)
                                                .collect(Collectors.toList());

                if (steps.isEmpty() && suggestion.getShortDescription() != null
                                && !suggestion.getShortDescription().isBlank()) {
                        steps = List.of(suggestion.getShortDescription().trim());
                }

                if (steps.isEmpty()) {
                        return null;
                }

                return new HotspotNearbyResponse.RecyclingSuggestion(
                                suggestion.getTitle(),
                                steps);
        }

        private Set<String> toCanonicalWasteTypeKeys(String wasteType) {
                String normalized = normalizeWasteType(wasteType);
                if (normalized.isEmpty()) {
                        return Set.of();
                }

                Set<String> keys = new LinkedHashSet<>();
                keys.add(normalized);

                if (normalized.contains("nhua") || normalized.contains("plastic") || normalized.contains("chai")) {
                        keys.add("nhua");
                        if (normalized.contains("chai")) {
                                keys.add("chai nhua");
                        }
                }
                if (normalized.contains("giay") || normalized.contains("bia") || normalized.contains("paper")
                                || normalized.contains("carton")) {
                        keys.add("giay");
                }
                if (normalized.contains("kim loai") || normalized.contains("metal") || normalized.contains("lon")) {
                        keys.add("kim loai");
                }
                if (normalized.contains("thuy tinh") || normalized.contains("glass")) {
                        keys.add("thuy tinh");
                }
                if (normalized.contains("huu co") || normalized.contains("organic") || normalized.contains("thuc an")) {
                        keys.add("huu co");
                }

                return keys;
        }

        private String normalizeWasteType(String rawType) {
                if (rawType == null) {
                        return "";
                }

                return Normalizer.normalize(rawType, Normalizer.Form.NFD)
                                .replaceAll("\\p{M}", "")
                                .toLowerCase(Locale.ROOT)
                                .replace('_', ' ')
                                .replace('-', ' ')
                                .replaceAll("\\s+", " ")
                                .trim();
        }

        private double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
                final double earthRadiusMeters = 6371000.0;
                double dLat = Math.toRadians(lat2 - lat1);
                double dLon = Math.toRadians(lon2 - lon1);
                double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                                                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
                double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                return earthRadiusMeters * c;
        }

        /**
         * Dự đoán hotspot cho toàn bộ báo cáo.
         */
        public HotspotPredictResponse predictAllReports(
                        LocalDateTime fromDate,
                        LocalDateTime toDate,
                        Integer horizonDays,
                        Integer gridSizeM,
                        Double topPercent,
                        Integer minPredictedCount,
                        Double dbscanEpsKm,
                        Integer dbscanMinSamples) {

                List<WasteReport> allReports = reportRepository.findAll();

                List<HotspotPredictRequest.ReportPoint> reportPoints = allReports.stream()
                                .filter(r -> r.getGpsLat() != null && r.getGpsLong() != null)
                                .filter(r -> fromDate == null || r.getCreatedAt().isAfter(fromDate)
                                                || r.getCreatedAt().isEqual(fromDate))
                                .filter(r -> toDate == null || r.getCreatedAt().isBefore(toDate)
                                                || r.getCreatedAt().isEqual(toDate))
                                .filter(r -> r.getStatus() == WasteReport.Status.VERIFIED
                                                || r.getStatus() == WasteReport.Status.CLEANED)
                                .map(r -> new HotspotPredictRequest.ReportPoint(
                                                r.getReportId(),
                                                r.getGpsLat().doubleValue(),
                                                r.getGpsLong().doubleValue(),
                                                r.getCreatedAt(),
                                                r.getUserId(),
                                                r.getCategory(),
                                                r.getAiVerified()))
                                .collect(Collectors.toList());

                if (reportPoints.isEmpty()) {
                        return new HotspotPredictResponse();
                }

                HotspotPredictRequest request = new HotspotPredictRequest(
                                reportPoints,
                                horizonDays != null ? horizonDays : 7,
                                gridSizeM != null ? gridSizeM : 200,
                                topPercent != null ? topPercent : 0.10,
                                minPredictedCount != null ? minPredictedCount : 3,
                                dbscanEpsKm != null ? dbscanEpsKm : 0.5,
                                dbscanMinSamples != null ? dbscanMinSamples : 2);

                try {
                        HotspotPredictResponse response = restTemplate.postForObject(
                                        fastApiPredictUrl,
                                        request,
                                        HotspotPredictResponse.class);
                        return response != null ? response : new HotspotPredictResponse();
                } catch (Exception e) {
                        System.err.println("Lỗi gọi FastAPI prediction: " + e.getMessage());
                        return new HotspotPredictResponse();
                }
        }

        /**
         * Dự đoán hotspot trong viewport bản đồ.
         */
        public HotspotPredictResponse predictReportsInArea(
                        Double minLat, Double maxLat, Double minLng, Double maxLng,
                        LocalDateTime fromDate,
                        LocalDateTime toDate,
                        Integer horizonDays,
                        Integer gridSizeM,
                        Double topPercent,
                        Integer minPredictedCount,
                        Double dbscanEpsKm,
                        Integer dbscanMinSamples) {

                List<HotspotPredictRequest.ReportPoint> reportPoints = reportRepository.findAll().stream()
                                .filter(r -> r.getGpsLat() != null && r.getGpsLong() != null)
                                .filter(r -> r.getGpsLat().doubleValue() >= minLat
                                                && r.getGpsLat().doubleValue() <= maxLat)
                                .filter(r -> r.getGpsLong().doubleValue() >= minLng
                                                && r.getGpsLong().doubleValue() <= maxLng)
                                .filter(r -> fromDate == null || r.getCreatedAt().isAfter(fromDate)
                                                || r.getCreatedAt().isEqual(fromDate))
                                .filter(r -> toDate == null || r.getCreatedAt().isBefore(toDate)
                                                || r.getCreatedAt().isEqual(toDate))
                                .filter(r -> r.getStatus() == WasteReport.Status.VERIFIED
                                                || r.getStatus() == WasteReport.Status.CLEANED)
                                .map(r -> new HotspotPredictRequest.ReportPoint(
                                                r.getReportId(),
                                                r.getGpsLat().doubleValue(),
                                                r.getGpsLong().doubleValue(),
                                                r.getCreatedAt(),
                                                r.getUserId(),
                                                r.getCategory(),
                                                r.getAiVerified()))
                                .collect(Collectors.toList());

                if (reportPoints.isEmpty()) {
                        return new HotspotPredictResponse();
                }

                HotspotPredictRequest request = new HotspotPredictRequest(
                                reportPoints,
                                horizonDays != null ? horizonDays : 7,
                                gridSizeM != null ? gridSizeM : 200,
                                topPercent != null ? topPercent : 0.10,
                                minPredictedCount != null ? minPredictedCount : 3,
                                dbscanEpsKm != null ? dbscanEpsKm : 0.5,
                                dbscanMinSamples != null ? dbscanMinSamples : 2);

                try {
                        HotspotPredictResponse response = restTemplate.postForObject(
                                        fastApiPredictUrl,
                                        request,
                                        HotspotPredictResponse.class);
                        return response != null ? response : new HotspotPredictResponse();
                } catch (Exception e) {
                        System.err.println("Lỗi gọi FastAPI prediction theo vùng: " + e.getMessage());
                        return new HotspotPredictResponse();
                }
        }
}
