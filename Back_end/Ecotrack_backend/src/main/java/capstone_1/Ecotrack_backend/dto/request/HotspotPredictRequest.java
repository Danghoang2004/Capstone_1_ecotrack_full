package capstone_1.Ecotrack_backend.dto.request;

import com.fasterxml.jackson.annotation.JsonFormat;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Request gửi sang FastAPI để dự đoán hotspot 7 ngày tới.
 */
public class HotspotPredictRequest {

    public static class ReportPoint {
        private Long id;
        private Double lat;
        private Double lng;
        @JsonFormat(pattern = "yyyy-MM-dd'T'HH:mm:ss")
        private LocalDateTime timestamp;
        private Long user_id;
        private String category;
        private Boolean ai_verified;

        public ReportPoint() {
        }

        public ReportPoint(Long id, Double lat, Double lng, LocalDateTime timestamp, Long user_id, String category,
                Boolean ai_verified) {
            this.id = id;
            this.lat = lat;
            this.lng = lng;
            this.timestamp = timestamp;
            this.user_id = user_id;
            this.category = category;
            this.ai_verified = ai_verified;
        }

        public Long getId() {
            return id;
        }

        public void setId(Long id) {
            this.id = id;
        }

        public Double getLat() {
            return lat;
        }

        public void setLat(Double lat) {
            this.lat = lat;
        }

        public Double getLng() {
            return lng;
        }

        public void setLng(Double lng) {
            this.lng = lng;
        }

        public LocalDateTime getTimestamp() {
            return timestamp;
        }

        public void setTimestamp(LocalDateTime timestamp) {
            this.timestamp = timestamp;
        }

        public Long getUser_id() {
            return user_id;
        }

        public void setUser_id(Long user_id) {
            this.user_id = user_id;
        }

        public String getCategory() {
            return category;
        }

        public void setCategory(String category) {
            this.category = category;
        }

        public Boolean getAi_verified() {
            return ai_verified;
        }

        public void setAi_verified(Boolean ai_verified) {
            this.ai_verified = ai_verified;
        }
    }

    private List<ReportPoint> reports;
    private Integer horizon_days;
    private Integer grid_size_m;
    private Double top_percent;
    private Integer min_predicted_count;
    private Double dbscan_eps_km;
    private Integer dbscan_min_samples;

    public HotspotPredictRequest() {
    }

    public HotspotPredictRequest(
            List<ReportPoint> reports,
            Integer horizon_days,
            Integer grid_size_m,
            Double top_percent,
            Integer min_predicted_count,
            Double dbscan_eps_km,
            Integer dbscan_min_samples) {
        this.reports = reports;
        this.horizon_days = horizon_days;
        this.grid_size_m = grid_size_m;
        this.top_percent = top_percent;
        this.min_predicted_count = min_predicted_count;
        this.dbscan_eps_km = dbscan_eps_km;
        this.dbscan_min_samples = dbscan_min_samples;
    }

    public List<ReportPoint> getReports() {
        return reports;
    }

    public void setReports(List<ReportPoint> reports) {
        this.reports = reports;
    }

    public Integer getHorizon_days() {
        return horizon_days;
    }

    public void setHorizon_days(Integer horizon_days) {
        this.horizon_days = horizon_days;
    }

    public Integer getGrid_size_m() {
        return grid_size_m;
    }

    public void setGrid_size_m(Integer grid_size_m) {
        this.grid_size_m = grid_size_m;
    }

    public Double getTop_percent() {
        return top_percent;
    }

    public void setTop_percent(Double top_percent) {
        this.top_percent = top_percent;
    }

    public Integer getMin_predicted_count() {
        return min_predicted_count;
    }

    public void setMin_predicted_count(Integer min_predicted_count) {
        this.min_predicted_count = min_predicted_count;
    }

    public Double getDbscan_eps_km() {
        return dbscan_eps_km;
    }

    public void setDbscan_eps_km(Double dbscan_eps_km) {
        this.dbscan_eps_km = dbscan_eps_km;
    }

    public Integer getDbscan_min_samples() {
        return dbscan_min_samples;
    }

    public void setDbscan_min_samples(Integer dbscan_min_samples) {
        this.dbscan_min_samples = dbscan_min_samples;
    }
}
