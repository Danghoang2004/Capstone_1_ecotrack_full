package capstone_1.Ecotrack_backend.controller.admin;

import capstone_1.Ecotrack_backend.dto.response.HotspotClusterResponse;
import capstone_1.Ecotrack_backend.dto.response.HotspotPredictResponse;
import capstone_1.Ecotrack_backend.service.HotspotClusteringService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

@RestController
@RequestMapping("/api/admin/hotspots")
@Tag(name = "Admin Hotspot", description = "API Admin: Dự đoán điểm nóng trên bản đồ nhiệt")
public class AdminHotspotController {

    @Autowired
    private HotspotClusteringService clusteringService;

    // Static DateTimeFormatter để tránh tạo lại nhiều lần
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ISO_DATE_TIME;

    // Validate geographic coordinates
    private void validateCoordinates(Double minLat, Double maxLat, Double minLng, Double maxLng)
            throws IllegalArgumentException {
        if (minLat == null || maxLat == null || minLng == null || maxLng == null) {
            throw new IllegalArgumentException("minLat, maxLat, minLng, maxLng không được rỗng");
        }

        if (minLat < -90 || maxLat > 90) {
            throw new IllegalArgumentException("Latitude phải trong khoảng [-90, 90]");
        }

        if (minLng < -180 || maxLng > 180) {
            throw new IllegalArgumentException("Longitude phải trong khoảng [-180, 180]");
        }

        if (minLat > maxLat) {
            throw new IllegalArgumentException("minLat phải <= maxLat");
        }

        if (minLng > maxLng) {
            throw new IllegalArgumentException("minLng phải <= maxLng");
        }
    }

    // Validate date range
    private void validateDateRange(LocalDateTime fromDate, LocalDateTime toDate)
            throws IllegalArgumentException {
        if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
            throw new IllegalArgumentException("fromDate phải <= toDate");
        }
    }

    // Validate clustering parameters
    private void validateClusteringParams(Double eps_km, Integer min_samples)
            throws IllegalArgumentException {
        if (eps_km != null && eps_km <= 0) {
            throw new IllegalArgumentException("eps_km phải > 0");
        }

        if (min_samples != null && min_samples < 1) {
            throw new IllegalArgumentException("min_samples phải >= 1");
        }
    }

    private void validatePredictionParams(
            Integer horizonDays,
            Integer gridSizeM,
            Double topPercent,
            Integer minPredictedCount,
            Double dbscanEpsKm,
            Integer dbscanMinSamples) {
        if (horizonDays != null && (horizonDays < 1 || horizonDays > 14)) {
            throw new IllegalArgumentException("horizonDays phải trong khoảng [1, 14]");
        }

        if (gridSizeM != null && (gridSizeM < 50 || gridSizeM > 1000)) {
            throw new IllegalArgumentException("gridSizeM phải trong khoảng [50, 1000]");
        }

        if (topPercent != null && (topPercent <= 0 || topPercent > 1)) {
            throw new IllegalArgumentException("topPercent phải trong khoảng (0, 1]");
        }

        if (minPredictedCount != null && minPredictedCount < 1) {
            throw new IllegalArgumentException("minPredictedCount phải >= 1");
        }

        if (dbscanEpsKm != null && dbscanEpsKm <= 0) {
            throw new IllegalArgumentException("dbscanEpsKm phải > 0");
        }

        if (dbscanMinSamples != null && dbscanMinSamples < 1) {
            throw new IllegalArgumentException("dbscanMinSamples phải >= 1");
        }
    }

    // Parse datetime string safely
    private LocalDateTime parseDatetime(String dateStr) throws DateTimeParseException {
        if (dateStr == null || dateStr.isEmpty()) {
            return null;
        }
        return LocalDateTime.parse(dateStr, DATE_FORMATTER);
    }

    @GetMapping("/predict/area")
    @Operation(summary = "Admin: Dự đoán hotspot 7 ngày tới trong viewport bản đồ")
    public ResponseEntity<?> adminPredictHotspotsInArea(
            @Parameter(description = "Vĩ độ tối thiểu") @RequestParam Double minLat,
            @Parameter(description = "Vĩ độ tối đa") @RequestParam Double maxLat,
            @Parameter(description = "Kinh độ tối thiểu") @RequestParam Double minLng,
            @Parameter(description = "Kinh độ tối đa") @RequestParam Double maxLng,
            @Parameter(description = "Thời gian bắt đầu (ISO-8601: 2024-01-01T00:00:00)") @RequestParam(required = false) String fromDate,
            @Parameter(description = "Thời gian kết thúc (ISO-8601: 2024-01-31T23:59:59)") @RequestParam(required = false) String toDate,
            @Parameter(description = "Số ngày dự đoán (1-14)") @RequestParam(required = false) Integer horizonDays,
            @Parameter(description = "Kích thước grid (m)") @RequestParam(required = false) Integer gridSizeM,
            @Parameter(description = "Top phần trăm ô rủi ro (0-1)") @RequestParam(required = false) Double topPercent,
            @Parameter(description = "Ngưỡng dự đoán tối thiểu") @RequestParam(required = false) Integer minPredictedCount,
            @Parameter(description = "DBSCAN eps (km)") @RequestParam(required = false) Double dbscanEpsKm,
            @Parameter(description = "DBSCAN min samples") @RequestParam(required = false) Integer dbscanMinSamples) {
        try {
            // Validate tọa độ bounding box
            validateCoordinates(minLat, maxLat, minLng, maxLng);

            // Parse thời gian
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            // Validate tham số
            validateDateRange(fromDateTime, toDateTime);
            validatePredictionParams(
                    horizonDays,
                    gridSizeM,
                    topPercent,
                    minPredictedCount,
                    dbscanEpsKm,
                    dbscanMinSamples);

            // Gọi service để dự đoán hotspot
            HotspotPredictResponse response = clusteringService.predictReportsInArea(
                    minLat,
                    maxLat,
                    minLng,
                    maxLng,
                    fromDateTime,
                    toDateTime,
                    horizonDays,
                    gridSizeM,
                    topPercent,
                    minPredictedCount,
                    dbscanEpsKm,
                    dbscanMinSamples);

            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * GET /api/admin/hotspots/predict
     * Dự đoán hotspot cho toàn bộ dữ liệu (7 ngày)
     */
    @GetMapping("/predict")
    @Operation(summary = "Admin: Dự đoán hotspot 7 ngày tới cho toàn bộ dữ liệu")
    public ResponseEntity<?> adminPredictAllHotspots(
            @Parameter(description = "Thời gian bắt đầu (ISO-8601)") @RequestParam(required = false) String fromDate,
            @Parameter(description = "Thời gian kết thúc (ISO-8601)") @RequestParam(required = false) String toDate,
            @Parameter(description = "Số ngày dự đoán (1-14)") @RequestParam(required = false) Integer horizonDays,
            @Parameter(description = "Kích thước grid (m)") @RequestParam(required = false) Integer gridSizeM,
            @Parameter(description = "Top phần trăm ô rủi ro (0-1)") @RequestParam(required = false) Double topPercent,
            @Parameter(description = "Ngưỡng dự đoán tối thiểu") @RequestParam(required = false) Integer minPredictedCount,
            @Parameter(description = "DBSCAN eps (km)") @RequestParam(required = false) Double dbscanEpsKm,
            @Parameter(description = "DBSCAN min samples") @RequestParam(required = false) Integer dbscanMinSamples) {
        try {
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            validateDateRange(fromDateTime, toDateTime);
            validatePredictionParams(
                    horizonDays,
                    gridSizeM,
                    topPercent,
                    minPredictedCount,
                    dbscanEpsKm,
                    dbscanMinSamples);

            HotspotPredictResponse response = clusteringService.predictAllReports(
                    fromDateTime,
                    toDateTime,
                    horizonDays,
                    gridSizeM,
                    topPercent,
                    minPredictedCount,
                    dbscanEpsKm,
                    dbscanMinSamples);

            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/cluster/area")
    @Operation(summary = "Admin: Gom nhóm báo cáo trong viewport bản đồ")
    public ResponseEntity<?> adminClusterReportsInArea(
            @Parameter(description = "Vĩ độ tối thiểu") @RequestParam Double minLat,
            @Parameter(description = "Vĩ độ tối đa") @RequestParam Double maxLat,
            @Parameter(description = "Kinh độ tối thiểu") @RequestParam Double minLng,
            @Parameter(description = "Kinh độ tối đa") @RequestParam Double maxLng,
            @Parameter(description = "Thời gian bắt đầu (ISO-8601)") @RequestParam(required = false) String fromDate,
            @Parameter(description = "Thời gian kết thúc (ISO-8601)") @RequestParam(required = false) String toDate,
            @Parameter(description = "Bán kính gom nhóm (km)") @RequestParam(required = false) Double eps_km,
            @Parameter(description = "Số báo cáo tối thiểu") @RequestParam(required = false) Integer min_samples) {
        try {
            // Validate tọa độ
            validateCoordinates(minLat, maxLat, minLng, maxLng);

            // Parse thời gian
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            // Validate tham số
            validateDateRange(fromDateTime, toDateTime);
            validateClusteringParams(eps_km, min_samples);

            // Gọi service để gom nhóm
            HotspotClusterResponse response = clusteringService.clusterReportsInArea(
                    minLat, maxLat, minLng, maxLng,
                    fromDateTime, toDateTime,
                    eps_km, min_samples);
            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    @GetMapping("/cluster")
    @Operation(summary = "Admin: Gom nhóm tất cả báo cáo")
    public ResponseEntity<?> adminClusterAllReports(
            @Parameter(description = "Thời gian bắt đầu (ISO-8601: 2024-01-01T00:00:00)") @RequestParam(required = false) String fromDate,
            @Parameter(description = "Thời gian kết thúc (ISO-8601: 2024-01-31T23:59:59)") @RequestParam(required = false) String toDate,
            @Parameter(description = "Bán kính gom nhóm (km)") @RequestParam(required = false) Double eps_km,
            @Parameter(description = "Số báo cáo tối thiểu để tạo hotspot") @RequestParam(required = false) Integer min_samples) {
        try {
            // Parse thời gian
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            // Validate tham số
            validateDateRange(fromDateTime, toDateTime);
            validateClusteringParams(eps_km, min_samples);

            // Gọi service
            HotspotClusterResponse response = clusteringService.clusterAllReports(
                    fromDateTime, toDateTime, eps_km, min_samples);
            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    static class ErrorResponse {
        private String code;
        private String message;
        private int status;
        private long timestamp;

        public ErrorResponse(String code, String message, int status) {
            this.code = code;
            this.message = message;
            this.status = status;
            this.timestamp = System.currentTimeMillis();
        }

        public String getCode() {
            return code;
        }

        public String getMessage() {
            return message;
        }

        public int getStatus() {
            return status;
        }

        public long getTimestamp() {
            return timestamp;
        }
    }
}
