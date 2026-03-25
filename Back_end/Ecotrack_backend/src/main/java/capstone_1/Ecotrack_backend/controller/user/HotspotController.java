package capstone_1.Ecotrack_backend.controller.user;

import capstone_1.Ecotrack_backend.dto.response.HotspotClusterResponse;
import capstone_1.Ecotrack_backend.service.HotspotClusteringService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;

/**
 * API endpoint để lấy hotspot (báo cáo đã gom nhóm bằng DBSCAN)
 */
@RestController
@RequestMapping("/api/public/hotspots")
@Tag(name = "Hotspot", description = "API lấy dữ liệu điểm nóng (hotspot)")
@Slf4j
public class HotspotController {

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

    // Parse datetime string safely
    private LocalDateTime parseDatetime(String dateStr) throws DateTimeParseException {
        if (dateStr == null || dateStr.isEmpty()) {
            return null;
        }
        return LocalDateTime.parse(dateStr, DATE_FORMATTER);
    }

    /**
     * Lấy danh sách hotspot của toàn bộ báo cáo
     */
    @GetMapping("/cluster")
    @Operation(summary = "Gom nhóm tất cả báo cáo thành hotspot")
    public ResponseEntity<?> getHotspots(
            @Parameter(description = "Thời gian bắt đầu (ISO-8601: 2024-01-01T00:00:00)") @RequestParam(required = false) String fromDate,

            @Parameter(description = "Thời gian kết thúc (ISO-8601: 2024-01-31T23:59:59)") @RequestParam(required = false) String toDate,

            @Parameter(description = "Bán kính gom nhóm (km)") @RequestParam(required = false) Double eps_km,

            @Parameter(description = "Số báo cáo tối thiểu để tạo hotspot") @RequestParam(required = false) Integer min_samples) {
        try {
            log.info("Nhận request GET /cluster. fromDate={}, toDate={}, eps_km={}, min_samples={}",
                    fromDate, toDate, eps_km, min_samples);

            // Parse datetime
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            // Validate parameters
            validateDateRange(fromDateTime, toDateTime);
            validateClusteringParams(eps_km, min_samples);

            log.debug("Validation thành công, gọi service...");

            // Call service and return response
            HotspotClusterResponse response = clusteringService.clusterAllReports(
                    fromDateTime, toDateTime, eps_km, min_samples);

            log.info("Request GET /cluster hoàn thành. Total clusters: {}", response.getTotal_clusters());

            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            log.warn("Lỗi định dạng ngày: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            log.warn("Tham số không hợp lệ: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            log.error("Lỗi server trong request GET /cluster: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Lấy hotspot trong một vùng (bounding box)
     * Dùng cho map viewport
     */
    @GetMapping("/cluster/area")
    @Operation(summary = "Gom nhóm báo cáo trong vùng địa lý cụ thể")
    public ResponseEntity<?> getHotspotsInArea(
            @Parameter(description = "Vĩ độ tối thiểu") @RequestParam Double minLat,

            @Parameter(description = "Vĩ độ tối đa") @RequestParam Double maxLat,

            @Parameter(description = "Kinh độ tối thiểu") @RequestParam Double minLng,

            @Parameter(description = "Kinh độ tối đa") @RequestParam Double maxLng,

            @Parameter(description = "Thời gian bắt đầu (ISO-8601)") @RequestParam(required = false) String fromDate,

            @Parameter(description = "Thời gian kết thúc (ISO-8601)") @RequestParam(required = false) String toDate,

            @Parameter(description = "Bán kính gom nhóm (km)") @RequestParam(required = false) Double eps_km,

            @Parameter(description = "Số báo cáo tối thiểu") @RequestParam(required = false) Integer min_samples) {
        try {
            log.info(
                    "Nhận request GET /cluster/area. Box: ({},{}) - ({},{}), fromDate={}, toDate={}, eps_km={}, min_samples={}",
                    minLat, minLng, maxLat, maxLng, fromDate, toDate, eps_km, min_samples);

            // Validate coordinates
            validateCoordinates(minLat, maxLat, minLng, maxLng);

            // Parse datetime
            LocalDateTime fromDateTime = parseDatetime(fromDate);
            LocalDateTime toDateTime = parseDatetime(toDate);

            // Validate parameters
            validateDateRange(fromDateTime, toDateTime);
            validateClusteringParams(eps_km, min_samples);

            log.debug("Validation thành công, gọi service...");

            // Call service and return response
            HotspotClusterResponse response = clusteringService.clusterReportsInArea(
                    minLat, maxLat, minLng, maxLng,
                    fromDateTime, toDateTime,
                    eps_km, min_samples);

            log.info("Request GET /cluster/area hoàn thành. Total clusters: {}", response.getTotal_clusters());

            return ResponseEntity.ok(response);

        } catch (DateTimeParseException e) {
            log.warn("Lỗi định dạng ngày: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(new ErrorResponse(
                    "INVALID_DATE_FORMAT",
                    "Định dạng ngày không hợp lệ. Sử dụng ISO-8601: yyyy-MM-ddTHH:mm:ss. Lỗi: " + e.getMessage(),
                    HttpStatus.BAD_REQUEST.value()));

        } catch (IllegalArgumentException e) {
            log.warn("Tham số không hợp lệ: {}", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNPROCESSABLE_ENTITY).body(new ErrorResponse(
                    "INVALID_PARAMETERS",
                    "Tham số không hợp lệ: " + e.getMessage(),
                    HttpStatus.UNPROCESSABLE_ENTITY.value()));

        } catch (Exception e) {
            log.error("Lỗi server trong request GET /cluster/area: {}", e.getMessage(), e);
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(new ErrorResponse(
                    "INTERNAL_ERROR",
                    "Lỗi server: " + e.getMessage(),
                    HttpStatus.INTERNAL_SERVER_ERROR.value()));
        }
    }

    /**
     * Inner class để trả về lỗi với format chuẩn
     */
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
